package com.joelisstic.bibleverseapp.bible_verse_widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.joelisstic.bibleverseapp.bible_verse_widget.R

class BibleVerseWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        // Fetch the new verse data set by Flutter
        val quote = widgetData.getString("widget_quote", "Delight yourself in the Lord...") ?: ""
        val reference = widgetData.getString("widget_reference", "Psalms 37:4") ?: ""

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            
            // Unique state keys for this specific widget instance
            val lastQuoteKey = "last_quote_$appWidgetId"
            val lastRefKey = "last_ref_$appWidgetId"
            val indexKey = "widget_index_$appWidgetId"

            val lastQuote = widgetData.getString(lastQuoteKey, "") ?: ""
            val lastRef = widgetData.getString(lastRefKey, "") ?: ""
            val currentIndex = widgetData.getInt(indexKey, 0)

            if (lastQuote.isEmpty() || lastQuote == quote) {
                // First load or no data change: Show current text without animation
                val targetQuoteId = if (currentIndex == 0) R.id.widget_quote_0 else R.id.widget_quote_1
                val targetRefId = if (currentIndex == 0) R.id.widget_reference_0 else R.id.widget_reference_1
                
                views.setTextViewText(targetQuoteId, quote)
                views.setTextViewText(targetRefId, reference)
                views.setInt(R.id.view_flipper, "setDisplayedChild", currentIndex)
            } else {
                // DATA CHANGED: Set up the horizontal slide transition
                // 1. Keep the OLD content on the currently visible slot
                // 2. Put the NEW content on the hidden slot
                if (currentIndex == 0) {
                    views.setTextViewText(R.id.widget_quote_0, lastQuote)
                    views.setTextViewText(R.id.widget_reference_0, lastRef)
                    views.setTextViewText(R.id.widget_quote_1, quote)
                    views.setTextViewText(R.id.widget_reference_1, reference)
                } else {
                    views.setTextViewText(R.id.widget_quote_1, lastQuote)
                    views.setTextViewText(R.id.widget_reference_1, lastRef)
                    views.setTextViewText(R.id.widget_quote_0, quote)
                    views.setTextViewText(R.id.widget_reference_0, reference)
                }

                // Ensure we start from the current view and then flip
                views.setInt(R.id.view_flipper, "setDisplayedChild", currentIndex)
                views.showNext(R.id.view_flipper)

                // Persist the new index for next time
                val nextIndex = if (currentIndex == 0) 1 else 0
                widgetData.edit().putInt(indexKey, nextIndex).apply()
            }
            
            // Save the current data as 'last' to detect changes on next update
            widgetData.edit()
                .putString(lastQuoteKey, quote)
                .putString(lastRefKey, reference)
                .apply()

            // Interaction: Tapping the widget triggers Flutter's background update
            val backgroundIntent = Intent("es.antonborri.home_widget.action.BACKGROUND").apply {
                setPackage(context.packageName)
                data = Uri.parse("bibleversewidget://update_verse")
            }
            
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            
            val pendingIntent = PendingIntent.getBroadcast(context, 0, backgroundIntent, flags)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
