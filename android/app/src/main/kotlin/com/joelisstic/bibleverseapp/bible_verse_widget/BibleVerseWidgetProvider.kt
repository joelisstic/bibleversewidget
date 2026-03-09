package com.joelisstic.bibleverseapp.bible_verse_widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import com.joelisstic.bibleverseapp.bible_verse_widget.R

class BibleVerseWidgetProvider : HomeWidgetProvider() {
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

                // Create a background intent to trigger the refresh
                // Using a unique URI ensures the broadcast is delivered to our backgroundCallback
                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("bibleversewidget://update_verse")
                )
                setOnClickPendingIntent(R.id.widget_root, backgroundIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
