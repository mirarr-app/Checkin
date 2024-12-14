package com.mirarrapp.checkin
import HomeWidgetGlanceWidgetReceiver
import androidx.glance.appwidget.GlanceAppWidget


class ObservableWidget : HomeWidgetGlanceWidgetReceiver<ObservableAppWidget>() {
    override val glanceAppWidget : ObservableAppWidget
            get() = ObservableAppWidget()
}