package com.joelisstic.bibleverseapp.bible_verse_widget

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.joelisstic.bibleverseapp.bible_verse_widget.R

class BibleVerseStackService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return BibleVerseStackFactory(this.applicationContext)
    }
}

class BibleVerseStackFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private var quotes = mutableListOf<String>()
    private var references = mutableListOf<String>()
    private val sharedPrefs: SharedPreferences = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

    override fun onCreate() {
        updateData()
    }

    override fun onDataSetChanged() {
        updateData()
    }

    private fun updateData() {
        val currentQuote = sharedPrefs.getString("widget_quote", "Delight yourself in the Lord...") ?: ""
        val currentRef = sharedPrefs.getString("widget_reference", "Psalms 37:4") ?: ""
        
        quotes.clear()
        references.clear()
        
        // Top card
        quotes.add(currentQuote)
        references.add(currentRef)
        
        // Add more to allow swiping
        quotes.add("For I know the plans I have for you...")
        references.add("Jeremiah 29:11")
        
        quotes.add("The Lord is my shepherd; I shall not want.")
        references.add("Psalms 23:1")
    }

    override fun onDestroy() {
        quotes.clear()
        references.clear()
    }

    override fun getCount(): Int = quotes.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_item)
        
        if (position < quotes.size) {
            views.setTextViewText(R.id.widget_quote, quotes[position])
            views.setTextViewText(R.id.widget_reference, references[position])
        }
        
        // Fill-in intent to allow the individual items to respond to clicks
        val fillInIntent = Intent()
        views.setOnClickFillInIntent(R.id.widget_item_root, fillInIntent)
        
        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
}
