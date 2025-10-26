#include <obs-module.h>
#include <obs-frontend-api.h>
#include <util/platform.h>
#include <graphics/image-file.h>
#include "measurement-reader.h"
#include <string>

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE("obs-measurement-overlay", "en-US")

MODULE_EXPORT const char *obs_module_description(void)
{
	return "Measurement overlay for DMM/LCR devices";
}

struct measurement_overlay_source {
	obs_source_t *source;
	MeasurementReader *reader;
	
	uint32_t width;
	uint32_t height;
	uint32_t font_size;
	int precision;
	bool show_units;
	
	char display_text[256];
	
	std::string device_id;
	std::string driver;
	std::string conn;
	std::string serialcomm;
};

static const char *measurement_overlay_get_name(void *unused)
{
	return obs_module_text("MeasurementOverlay");
}

static void *measurement_overlay_create(obs_data_t *settings, obs_source_t *source)
{
	struct measurement_overlay_source *context = (struct measurement_overlay_source *)
		bzalloc(sizeof(struct measurement_overlay_source));
	
	context->source = source;
	context->reader = new MeasurementReader();
	context->width = 400;
	context->height = 100;
	context->font_size = 24;
	context->precision = 3;
	context->show_units = true;
	
	strcpy(context->display_text, "No measurement data");
	
	// Start reader with settings
	const char *device = obs_data_get_string(settings, "device");
	const char *driver = obs_data_get_string(settings, "driver");
	const char *conn = obs_data_get_string(settings, "conn");
	const char *serialcomm = obs_data_get_string(settings, "serialcomm");
	
	context->reader->start(device ? device : "", driver ? driver : "",
	                       conn ? conn : "", serialcomm ? serialcomm : "");
	
	return context;
}

static void measurement_overlay_destroy(void *data)
{
	struct measurement_overlay_source *context = (struct measurement_overlay_source *)data;
	
	if (context->reader) {
		context->reader->stop();
		delete context->reader;
	}
	
	bfree(context);
}

static void measurement_overlay_update(void *data, obs_data_t *settings)
{
	struct measurement_overlay_source *context = (struct measurement_overlay_source *)data;
	
	context->width = (uint32_t)obs_data_get_int(settings, "width");
	context->height = (uint32_t)obs_data_get_int(settings, "height");
	context->font_size = (uint32_t)obs_data_get_int(settings, "font_size");
	context->precision = (int)obs_data_get_int(settings, "precision");
	context->show_units = obs_data_get_bool(settings, "show_units");
	
	// Restart reader with new settings
	const char *device = obs_data_get_string(settings, "device");
	const char *driver = obs_data_get_string(settings, "driver");
	const char *conn = obs_data_get_string(settings, "conn");
	const char *serialcomm = obs_data_get_string(settings, "serialcomm");
	
	context->reader->stop();
	context->reader->start(device ? device : "", driver ? driver : "",
	                       conn ? conn : "", serialcomm ? serialcomm : "");
}

static void measurement_overlay_video_tick(void *data, float seconds)
{
	struct measurement_overlay_source *context = (struct measurement_overlay_source *)data;
	
	float value;
	int unit;
	
	if (context->reader->get_latest_measurement(value, unit)) {
		const char *unit_str = "";
		if (context->show_units) {
			switch (unit) {
				case 10001: unit_str = " A"; break;  // OTC_MQ_CURRENT
				case 10002: unit_str = " Ω"; break;  // OTC_MQ_RESISTANCE
				case 10003: unit_str = " F"; break;  // OTC_MQ_CAPACITANCE
				case 10004: unit_str = " H"; break;  // OTC_MQ_INDUCTANCE
				case 10005: unit_str = " Hz"; break; // OTC_MQ_FREQUENCY
				default: unit_str = " V"; break;     // OTC_MQ_VOLTAGE
			}
		}
		
		snprintf(context->display_text, sizeof(context->display_text), 
		        "%.*f%s", context->precision, value, unit_str);
	}
}

static void measurement_overlay_video_render(void *data, gs_effect_t *effect)
{
	struct measurement_overlay_source *context = (struct measurement_overlay_source *)data;
	
	// Simple colored rectangle as background
	gs_effect_t *solid = obs_get_base_effect(OBS_EFFECT_SOLID);
	gs_eparam_t *color = gs_effect_get_param_by_name(solid, "color");
	gs_technique_t *tech = gs_effect_get_technique(solid, "Solid");
	
	struct vec4 bg_color;
	vec4_set(&bg_color, 0.0f, 0.0f, 0.0f, 0.5f);
	gs_effect_set_vec4(color, &bg_color);
	
	gs_technique_begin(tech);
	gs_technique_begin_pass(tech, 0);
	
	gs_render_start(true);
	gs_vertex2f(0, 0);
	gs_vertex2f(context->width, 0);
	gs_vertex2f(0, context->height);
	gs_vertex2f(context->width, context->height);
	gs_render_stop(GS_TRISTRIP);
	
	gs_technique_end_pass(tech);
	gs_technique_end(tech);
	
	// Note: Text rendering requires platform-specific implementation
	// For now, just render the background
	UNUSED_PARAMETER(effect);
}

static uint32_t measurement_overlay_get_width(void *data)
{
	struct measurement_overlay_source *context = (struct measurement_overlay_source *)data;
	return context->width;
}

static uint32_t measurement_overlay_get_height(void *data)
{
	struct measurement_overlay_source *context = (struct measurement_overlay_source *)data;
	return context->height;
}

static void measurement_overlay_get_defaults(obs_data_t *settings)
{
	obs_data_set_default_string(settings, "device", "");
	obs_data_set_default_string(settings, "driver", "");
	obs_data_set_default_string(settings, "conn", "");
	obs_data_set_default_string(settings, "serialcomm", "");
	obs_data_set_default_int(settings, "width", 400);
	obs_data_set_default_int(settings, "height", 100);
	obs_data_set_default_int(settings, "font_size", 24);
	obs_data_set_default_int(settings, "precision", 3);
	obs_data_set_default_bool(settings, "show_units", true);
}

static obs_properties_t *measurement_overlay_get_properties(void *data)
{
	struct measurement_overlay_source *context = (struct measurement_overlay_source *)data;
	
	obs_properties_t *props = obs_properties_create();
	
	// Device selection
	obs_property_t *device_list = obs_properties_add_list(props, "device",
		obs_module_text("MeasurementOverlay.Device"),
		OBS_COMBO_TYPE_LIST, OBS_COMBO_FORMAT_STRING);
	obs_property_list_add_string(device_list, 
		obs_module_text("MeasurementOverlay.AutoDetect"), "");
	
	if (context && context->reader) {
		auto devices = context->reader->scan_devices();
		for (const auto &dev : devices) {
			obs_property_list_add_string(device_list, 
				dev.display_name.c_str(), dev.id.c_str());
		}
	}
	
	// Manual configuration
	obs_properties_add_text(props, "driver", 
		obs_module_text("MeasurementOverlay.Driver"), OBS_TEXT_DEFAULT);
	obs_properties_add_text(props, "conn",
		obs_module_text("MeasurementOverlay.Connection"), OBS_TEXT_DEFAULT);
	obs_properties_add_text(props, "serialcomm",
		obs_module_text("MeasurementOverlay.SerialConfig"), OBS_TEXT_DEFAULT);
	
	// Display settings
	obs_properties_add_int_slider(props, "width",
		obs_module_text("MeasurementOverlay.Width"), 200, 800, 50);
	obs_properties_add_int_slider(props, "height",
		obs_module_text("MeasurementOverlay.Height"), 50, 200, 10);
	obs_properties_add_int_slider(props, "font_size",
		obs_module_text("MeasurementOverlay.FontSize"), 12, 48, 2);
	obs_properties_add_int_slider(props, "precision",
		obs_module_text("MeasurementOverlay.Precision"), 0, 6, 1);
	
	obs_properties_add_bool(props, "show_units",
		obs_module_text("MeasurementOverlay.ShowUnits"));
	
	return props;
}

bool obs_module_load(void)
{
	struct obs_source_info info = {};
	info.id = "measurement_overlay";
	info.type = OBS_SOURCE_TYPE_INPUT;
	info.output_flags = OBS_SOURCE_VIDEO | OBS_SOURCE_CUSTOM_DRAW;
	info.get_name = measurement_overlay_get_name;
	info.create = measurement_overlay_create;
	info.destroy = measurement_overlay_destroy;
	info.update = measurement_overlay_update;
	info.get_defaults = measurement_overlay_get_defaults;
	info.get_properties = measurement_overlay_get_properties;
	info.get_width = measurement_overlay_get_width;
	info.get_height = measurement_overlay_get_height;
	info.video_tick = measurement_overlay_video_tick;
	info.video_render = measurement_overlay_video_render;
	
	obs_register_source(&info);
	blog(LOG_INFO, "measurement overlay plugin loaded (version %s)", "0.1.0");
	return true;
}

void obs_module_unload(void)
{
	blog(LOG_INFO, "measurement overlay plugin unloaded");
}
