#pragma once

#include <thread>
#include <mutex>
#include <atomic>

struct otc_context;
struct otc_dev_inst;
struct otc_datafeed_packet;

class MeasurementReader {
public:
    MeasurementReader();
    ~MeasurementReader();
    
    bool start();
    void stop();
    bool get_latest_measurement(float &value, int &unit);
    
private:
    void read_loop();
    static void data_callback(const struct otc_dev_inst *sdi, 
                            const struct otc_datafeed_packet *packet, 
                            void *cb_data);
    
    std::atomic<bool> running;
    std::thread reader_thread;
    std::mutex data_mutex;
    
    struct otc_context *context;
    float latest_value = 0.0f;
    int latest_unit = 0;
    bool has_new_data = false;
};
