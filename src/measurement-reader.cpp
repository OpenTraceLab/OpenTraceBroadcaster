#include "measurement-reader.h"
#include <opentracecapture/opentracecapture.h>
#include <thread>
#include <chrono>
#include <cstring>

MeasurementReader::MeasurementReader() : running(false), context(nullptr), selected_device(nullptr) {}

MeasurementReader::~MeasurementReader() {
    stop();
}

std::vector<DeviceInfo> MeasurementReader::scan_devices() {
    std::vector<DeviceInfo> result;
    
    struct otc_context *scan_ctx = nullptr;
    if (otc_init(&scan_ctx) != OTC_OK) {
        return result;
    }
    
    GSList *all_devices = nullptr;
    GSList *drivers = otc_driver_list(scan_ctx);
    
    for (GSList *l = drivers; l; l = l->next) {
        struct otc_dev_driver *driver = (struct otc_dev_driver *)l->data;
        GSList *devs = otc_driver_scan(driver, nullptr);
        if (devs) {
            all_devices = g_slist_concat(all_devices, devs);
        }
    }
    
    for (GSList *l = all_devices; l; l = l->next) {
        struct otc_dev_inst *sdi = (struct otc_dev_inst *)l->data;
        DeviceInfo info;
        
        const char *vendor = otc_dev_inst_vendor_get(sdi);
        const char *model = otc_dev_inst_model_get(sdi);
        const char *conn = otc_dev_inst_connection_id_get(sdi);
        
        info.display_name = std::string(vendor ? vendor : "Unknown") + " " + 
                           std::string(model ? model : "Device");
        if (conn) {
            info.display_name += " (" + std::string(conn) + ")";
            info.id = conn;
        } else {
            info.id = std::to_string((uintptr_t)sdi);
        }
        info.device = sdi;
        result.push_back(info);
    }
    
    g_slist_free(all_devices);
    otc_exit(scan_ctx);
    
    return result;
}

bool MeasurementReader::start(const std::string &device_id, const std::string &driver,
                              const std::string &conn, const std::string &serialcomm) {
    if (running) return true;
    
    device_id_ = device_id;
    driver_ = driver;
    conn_ = conn;
    serialcomm_ = serialcomm;
    
    if (otc_init(&context) != OTC_OK) {
        return false;
    }
    
    running = true;
    reader_thread = std::thread(&MeasurementReader::read_loop, this);
    return true;
}

void MeasurementReader::stop() {
    if (!running) return;
    
    running = false;
    if (reader_thread.joinable()) {
        reader_thread.join();
    }
    
    if (context) {
        otc_exit(context);
        context = nullptr;
    }
    selected_device = nullptr;
}

void MeasurementReader::read_loop() {
    struct otc_session *session = nullptr;
    GSList *devices = nullptr;
    
    if (otc_session_new(context, &session) != OTC_OK) {
        running = false;
        return;
    }
    
    // Scan for devices with optional filters
    GSList *drivers = otc_driver_list(context);
    for (GSList *l = drivers; l; l = l->next) {
        struct otc_dev_driver *driver = (struct otc_dev_driver *)l->data;
        
        // Filter by driver name if specified
        if (!driver_.empty()) {
            const char *drv_name = otc_dev_driver_name_get(driver);
            if (!drv_name || driver_ != drv_name) {
                continue;
            }
        }
        
        // Build scan options if conn/serialcomm specified
        GSList *scan_opts = nullptr;
        if (!conn_.empty()) {
            struct otc_config *opt = (struct otc_config *)g_malloc(sizeof(struct otc_config));
            opt->key = OTC_CONF_CONN;
            opt->data = g_variant_new_string(conn_.c_str());
            scan_opts = g_slist_append(scan_opts, opt);
        }
        if (!serialcomm_.empty()) {
            struct otc_config *opt = (struct otc_config *)g_malloc(sizeof(struct otc_config));
            opt->key = OTC_CONF_SERIALCOMM;
            opt->data = g_variant_new_string(serialcomm_.c_str());
            scan_opts = g_slist_append(scan_opts, opt);
        }
        
        GSList *devs = otc_driver_scan(driver, scan_opts);
        
        // Free scan options
        for (GSList *o = scan_opts; o; o = o->next) {
            struct otc_config *opt = (struct otc_config *)o->data;
            g_variant_unref(opt->data);
            g_free(opt);
        }
        g_slist_free(scan_opts);
        
        if (devs) {
            devices = g_slist_concat(devices, devs);
        }
    }
    
    if (!devices) {
        otc_session_destroy(session);
        running = false;
        return;
    }
    
    // Select device by ID if specified, otherwise use first
    struct otc_dev_inst *sdi = nullptr;
    if (!device_id_.empty()) {
        for (GSList *l = devices; l; l = l->next) {
            struct otc_dev_inst *dev = (struct otc_dev_inst *)l->data;
            const char *conn = otc_dev_inst_connection_id_get(dev);
            if (conn && device_id_ == conn) {
                sdi = dev;
                break;
            }
        }
    }
    if (!sdi) {
        sdi = (struct otc_dev_inst *)devices->data;
    }
    
    selected_device = sdi;
    
    if (otc_dev_open(sdi) != OTC_OK) {
        g_slist_free(devices);
        otc_session_destroy(session);
        running = false;
        return;
    }
    
    otc_session_dev_add(session, sdi);
    otc_session_datafeed_callback_add(session, data_callback, this);
    
    if (otc_session_start(session) != OTC_OK) {
        otc_dev_close(sdi);
        g_slist_free(devices);
        otc_session_destroy(session);
        running = false;
        return;
    }
    
    while (running) {
        otc_session_run(session);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    otc_session_stop(session);
    otc_dev_close(sdi);
    g_slist_free(devices);
    otc_session_destroy(session);
}

void MeasurementReader::data_callback(const struct otc_dev_inst *sdi, 
                                    const struct otc_datafeed_packet *packet, 
                                    void *cb_data) {
    MeasurementReader *reader = static_cast<MeasurementReader*>(cb_data);
    
    if (packet->type == OTC_DF_ANALOG) {
        const struct otc_datafeed_analog *analog = 
            (const struct otc_datafeed_analog *)packet->payload;
        
        if (analog->num_samples > 0) {
            float value;
            if (otc_analog_to_float(analog, &value) == OTC_OK) {
                std::lock_guard<std::mutex> lock(reader->data_mutex);
                reader->latest_value = value;
                reader->latest_unit = analog->meaning->unit;
                reader->has_new_data = true;
            }
        }
    }
}

bool MeasurementReader::get_latest_measurement(float &value, int &unit) {
    std::lock_guard<std::mutex> lock(data_mutex);
    if (!has_new_data) return false;
    
    value = latest_value;
    unit = latest_unit;
    has_new_data = false;
    return true;
}
