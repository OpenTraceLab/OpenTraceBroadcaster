#pragma once

#include <thread>
#include <mutex>
#include <atomic>
#include <string>
#include <vector>

struct otc_context;
struct otc_dev_inst;
struct otc_datafeed_packet;

struct DeviceInfo {
    std::string id;
    std::string display_name;
    struct otc_dev_inst *device;
};

class MeasurementReader {
public:
    MeasurementReader();
    ~MeasurementReader();
    
    bool start(const std::string &device_id = "", const std::string &driver = "", 
               const std::string &conn = "", const std::string &serialcomm = "");
    void stop();
    bool get_latest_measurement(float &value, int &unit);
    std::vector<DeviceInfo> scan_devices();
    
private:
    void read_loop();
    static void data_callback(const struct otc_dev_inst *sdi, 
                            const struct otc_datafeed_packet *packet, 
                            void *cb_data);
    
    std::atomic<bool> running;
    std::thread reader_thread;
    std::mutex data_mutex;
    
    struct otc_context *context;
    struct otc_dev_inst *selected_device;
    float latest_value = 0.0f;
    int latest_unit = 0;
    bool has_new_data = false;
    
    std::string device_id_;
    std::string driver_;
    std::string conn_;
    std::string serialcomm_;
};
