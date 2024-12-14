package com.mirarrapp.checkin
import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import android.graphics.BitmapFactory
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.Text
import java.lang.reflect.Modifier

class ObservableAppWidget : GlanceAppWidget(){

    override val stateDefinition : GlanceStateDefinition<*>?
        get() = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceContent(context, currentState())
        }
    }

    @Composable
    private fun GlanceContent(context: Context, currentState:HomeWidgetGlanceState){
        val prefs= currentState.preferences
        val imagePath = prefs.getString("CalendarWidget" ,null)
        Box(modifier = GlanceModifier.background(Color.Transparent).fillMaxSize()) {
                imagePath?.let {
                    val bitmap = BitmapFactory.decodeFile(it)
                    Image(provider = androidx.glance.ImageProvider(bitmap), contentDescription = "First Calendar", GlanceModifier.fillMaxSize())
                }

        }
    }
}