#include <obs-module.h>
#include <graphics/graphics.h>
#include <util/platform.h>
#include "measurement-reader.h"
#include <string>

struct measurement_overlay_source {
    obs_source_t *source;
    MeasurementReader *reader;
    uint32_t width;
    uint32_t height;
    char display_text[256];
    bool text_updated;
};

static const char *measurement_overlay_get_name(void *unused) {
    UNUSED_PARAMETER(unused);
    return "Measurement Overlay";
}

static void *measurement_overlay_create(obs_data_t *settings, obs_source_t *source) {
    UNUSED_PARAMETER(settings);
    
    struct measurement_overlay_source *context = 
        (struct measurement_overlay_source *)bzalloc(sizeof(struct measurement_overlay_source));
    
    context->source = source;
    context->reader = new MeasurementReader();
    context->width = 800;
    context->height = 600;
    strcpy(context->display_text, "No measurement data");
    context->text_updated = true;
    
    return context;
}

static void measurement_overlay_destroy(void *data) {
    struct measurement_overlay_source *context = 
        (struct measurement_overlay_source *)data;
    
    if (context) {
        delete context->reader;
        bfree(context);
    }
}

static void measurement_overlay_update(void *data, obs_data_t *settings) {
    UNUSED_PARAMETER(settings);
    struct measurement_overlay_source *context = 
        (struct measurement_overlay_source *)data;
    
    if (context && context->reader) {
        float value;
        int unit;
        if (context->reader->get_latest_measurement(value, unit)) {
            snprintf(context->display_text, sizeof(context->display_text), 
                    "%.3f (unit: %d)", value, unit);
            context->text_updated = true;
        }
    }
}

static void measurement_overlay_video_tick(void *data, float seconds) {
    UNUSED_PARAMETER(seconds);
    measurement_overlay_update(data, nullptr);
}

static void measurement_overlay_video_render(void *data, gs_effect_t *effect) {
    UNUSED_PARAMETER(effect);
    struct measurement_overlay_source *context = 
        (struct measurement_overlay_source *)data;
    
    if (!context) return;
    
    // Simple colored rectangle as placeholder for text
    gs_effect_t *solid = obs_get_base_effect(OBS_EFFECT_SOLID);
    gs_eparam_t *color = gs_effect_get_param_by_name(solid, "color");
    
    struct vec4 colorVal;
    vec4_set(&colorVal, 1.0f, 1.0f, 1.0f, 1.0f); // White
    gs_effect_set_vec4(color, &colorVal);
    
    gs_technique_t *tech = gs_effect_get_technique(solid, "Solid");
    gs_technique_begin(tech);
    gs_technique_begin_pass(tech, 0);
    
    gs_draw_sprite(nullptr, 0, 200, 50); // Simple rectangle
    
    gs_technique_end_pass(tech);
    gs_technique_end(tech);
}

static uint32_t measurement_overlay_get_width(void *data) {
    struct measurement_overlay_source *context = 
        (struct measurement_overlay_source *)data;
    return context ? context->width : 0;
}

static uint32_t measurement_overlay_get_height(void *data) {
    struct measurement_overlay_source *context = 
        (struct measurement_overlay_source *)data;
    return context ? context->height : 0;
}

struct obs_source_info measurement_overlay_source_info = {
    .id = "measurement_overlay_source",
    .type = OBS_SOURCE_TYPE_INPUT,
    .output_flags = OBS_SOURCE_VIDEO,
    .get_name = measurement_overlay_get_name,
    .create = measurement_overlay_create,
    .destroy = measurement_overlay_destroy,
    .get_width = measurement_overlay_get_width,
    .get_height = measurement_overlay_get_height,
    .update = measurement_overlay_update,
    .video_tick = measurement_overlay_video_tick,
    .video_render = measurement_overlay_video_render,
};
