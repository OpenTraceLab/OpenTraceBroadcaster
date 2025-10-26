#include "measurement-reader.h"
#include <opentracecapture/opentracecapture.h>
#include <thread>
#include <chrono>

MeasurementReader::MeasurementReader() : running(false), context(nullptr) {}

MeasurementReader::~MeasurementReader() {
    stop();
}

bool MeasurementReader::start() {
    if (running) return true;
    
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
}

void MeasurementReader::read_loop() {
    struct otc_session *session = nullptr;
    GSList *devices = nullptr;
    
    if (otc_session_new(context, &session) != OTC_OK) {
        running = false;
        return;
    }
    
    GSList *drivers = otc_driver_list(context);
    for (GSList *l = drivers; l; l = l->next) {
        struct otc_dev_driver *driver = (struct otc_dev_driver *)l->data;
        GSList *devs = otc_driver_scan(driver, nullptr);
        if (devs) {
            devices = g_slist_concat(devices, devs);
        }
    }
    
    if (!devices) {
        otc_session_destroy(session);
        running = false;
        return;
    }
    
    struct otc_dev_inst *sdi = (struct otc_dev_inst *)devices->data;
    
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
