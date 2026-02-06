# Lesson Schedule Proposal & Add to Calendar

## Dependencies

- `add_2_calendar: ^3.0.1` – adds events to the device's default calendar
- `intl` (already present) – for date/time formatting

## Platform Setup (add_2_calendar)

### Android

Calendar permissions are already in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_CALENDAR" />
<uses-permission android:name="android.permission.WRITE_CALENDAR" />
```

For API 30+ package visibility, add inside `<queries>`:
```xml
<intent>
    <action android:name="android.intent.action.INSERT" />
    <data android:mimeType="vnd.android.cursor.item/event" />
</intent>
```

### iOS

In `Info.plist`:
- `NSCalendarsUsageDescription` – already present
- `NSContactsUsageDescription` – recommended for location autocomplete when the calendar UI opens (add if missing)
