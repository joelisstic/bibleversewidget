package com.joelisstic.bibleverseapp.bible_verse_widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.joelisstic.bibleverseapp.bible_verse_widget.R

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val quote = widgetData.getString("widget_quote", "Delight yourself in the Lord...")
                val reference = widgetData.getString("widget_reference", "Psalms 37:4")

                setTextViewText(R.id.widget_quote, quote)
                setTextViewText(R.id.widget_reference, reference)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
