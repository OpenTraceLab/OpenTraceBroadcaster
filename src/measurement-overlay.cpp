#include <obs-module.h>
#include <graphics/graphics.h>
#include <util/platform.h>
#include "measurement-reader.h"
#include <string>

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE("obs-measurement-overlay", "en-US")

struct measurement_overlay_source {
    obs_source_t *source;
    MeasurementReader *reader;
    
    uint32_t width;
    uint32_t height;
    gs_font_t *font;
    
    char display_text[256];
    bool text_updated;
    
    // Settings
    int precision;
    bool show_units;
    bool auto_range;
};

static const char *measurement_overlay_get_name(void *unused) {
    return "Measurement Overlay";
}

static void *measurement_overlay_create(obs_data_t *settings, obs_source_t *source) {
    struct measurement_overlay_source *context = 
        (struct measurement_overlay_source *)bzalloc(sizeof(struct measurement_overlay_source));
    
    context->source = source;
    context->reader = new MeasurementReader();
    context->width = 400;
    context->height = 100;
    
    // Create font
    struct gs_font_desc font_desc = {};
    font_desc.size = 24;
    font_desc.flags = GS_FONT_BOLD;
    strcpy(font_desc.face, "Arial");
    
    obs_enter_graphics();
    context->font = gs_font_create(&font_desc);
    obs_leave_graphics();
    
    strcpy(context->display_text, "No measurement data");
    
    // Initialize settings
    context->precision = 3;
    context->show_units = true;
    context->auto_range = true;
    
    // Start measurement reader
    context->reader->start();
    
    return context;
}

static void measurement_overlay_destroy(void *data) {
    struct measurement_overlay_source *context = 
        (struct measurement_overlay_source *)data;
    
    if (context->reader) {
        context->reader->stop();
        delete context->reader;
    }
    
    obs_enter_graphics();
    if (context->font) {
        gs_font_destroy(context->font);
    }
    obs_leave_graphics();
    
    bfree(context);
}

static void measurement_overlay_update(void *data, obs_data_t *settings) {
    struct measurement_overlay_source *context = 
        (struct measurement_overlay_source *)data;
    
    context->width = (uint32_t)obs_data_get_int(settings, "width");
    context->height = (uint32_t)obs_data_get_int(settings, "height");
    context->precision = (int)obs_data_get_int(settings, "precision");
    context->show_units = obs_data_get_bool(settings, "show_units");
    context->auto_range = obs_data_get_bool(settings, "auto_range");
    
    // Update font size
    int font_size = (int)obs_data_get_int(settings, "font_size");
    if (context->font) {
        obs_enter_graphics();
        gs_font_destroy(context->font);
        
        struct gs_font_desc font_desc = {};
        font_desc.size = font_size;
        font_desc.flags = GS_FONT_BOLD;
        strcpy(font_desc.face, "Arial");
        context->font = gs_font_create(&font_desc);
        obs_leave_graphics();
    }
}

static void measurement_overlay_video_tick(void *data, float seconds) {
    struct measurement_overlay_source *context = 
        (struct measurement_overlay_source *)data;
    
    float value;
    int unit;
    
    if (context->reader->get_latest_measurement(value, unit)) {
        const char *unit_str = "";
        if (context->show_units) {
            switch (unit) {
                case 1: unit_str = " A"; break;  // Current
                case 2: unit_str = " Ω"; break;  // Resistance
                case 3: unit_str = " F"; break;  // Capacitance
                case 4: unit_str = " H"; break;  // Inductance
                case 5: unit_str = " Hz"; break; // Frequency
                default: unit_str = " V"; break; // Voltage
            }
        }
        
        snprintf(context->display_text, sizeof(context->display_text), 
                "%.*f%s", context->precision, value, unit_str);
        context->text_updated = true;
    }
}

static void measurement_overlay_video_render(void *data, gs_effect_t *effect) {
    struct measurement_overlay_source *context = 
        (struct measurement_overlay_source *)data;
    
    if (!context->font) return;
    
    // Set up rendering
    gs_effect_t *solid_effect = obs_get_base_effect(OBS_EFFECT_SOLID);
    gs_technique_t *tech = gs_effect_get_technique(solid_effect, "Solid");
    
    // Draw background
    gs_effect_set_color(gs_effect_get_param_by_name(solid_effect, "color"), 
                       0x80000000); // Semi-transparent black
    
    gs_technique_begin(tech);
    gs_technique_begin_pass(tech, 0);
    
    gs_matrix_push();
    gs_matrix_identity();
    gs_render_start(true);
    
    gs_vertex2f(0, 0);
    gs_vertex2f(context->width, 0);
    gs_vertex2f(context->width, context->height);
    gs_vertex2f(0, context->height);
    
    gs_render_stop(GS_TRISTRIP);
    gs_matrix_pop();
    
    gs_technique_end_pass(tech);
    gs_technique_end(tech);
    
    // Draw text
    struct gs_font_render_params params = {};
    params.font = context->font;
    params.text = context->display_text;
    params.x = 10;
    params.y = 30;
    params.color = 0xFFFFFFFF; // White text
    
    gs_font_render(&params);
}

static uint32_t measurement_overlay_get_width(void *data) {
    struct measurement_overlay_source *context = 
        (struct measurement_overlay_source *)data;
    return context->width;
}

static uint32_t measurement_overlay_get_height(void *data) {
    struct measurement_overlay_source *context = 
        (struct measurement_overlay_source *)data;
    return context->height;
}

static obs_properties_t *measurement_overlay_get_properties(void *data) {
    obs_properties_t *props = obs_properties_create();
    
    obs_properties_add_int_slider(props, "width", "Width", 200, 800, 50);
    obs_properties_add_int_slider(props, "height", "Height", 50, 200, 10);
    obs_properties_add_int_slider(props, "font_size", "Font Size", 12, 48, 2);
    
    obs_property_t *precision = obs_properties_add_int_slider(props, "precision", 
                                                             "Decimal Places", 0, 6, 1);
    
    obs_properties_add_bool(props, "show_units", "Show Units");
    obs_properties_add_bool(props, "auto_range", "Auto Range");
    
    obs_properties_add_text(props, "info", 
                           "Connect DMM/LCR device and measurements will appear automatically", 
                           OBS_TEXT_INFO);
    
    return props;
}

static void measurement_overlay_get_defaults(obs_data_t *settings) {
    obs_data_set_default_int(settings, "width", 400);
    obs_data_set_default_int(settings, "height", 100);
    obs_data_set_default_int(settings, "font_size", 24);
    obs_data_set_default_int(settings, "precision", 3);
    obs_data_set_default_bool(settings, "show_units", true);
    obs_data_set_default_bool(settings, "auto_range", true);
}

static struct obs_source_info measurement_overlay_source_info = {
    .id = "measurement_overlay",
    .type = OBS_SOURCE_TYPE_INPUT,
    .output_flags = OBS_SOURCE_VIDEO | OBS_SOURCE_CUSTOM_DRAW,
    .get_name = measurement_overlay_get_name,
    .create = measurement_overlay_create,
    .destroy = measurement_overlay_destroy,
    .update = measurement_overlay_update,
    .video_tick = measurement_overlay_video_tick,
    .video_render = measurement_overlay_video_render,
    .get_width = measurement_overlay_get_width,
    .get_height = measurement_overlay_get_height,
    .get_properties = measurement_overlay_get_properties,
    .get_defaults = measurement_overlay_get_defaults,
};

bool obs_module_load(void) {
    obs_register_source(&measurement_overlay_source_info);
    return true;
}

void obs_module_unload(void) {
}
