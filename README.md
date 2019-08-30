# ⏲ Time Tracker

Simple app to track time and generate a report based on a specific template. This app will not be displayed in the mac OS dock, just in the mac OS status bar.

Output example:

`2019-08-02`

`17:22	17:57	Project Manager	Cost Center	Project	Task`

`2019-08-03`

`10:59	11:06	Project Manager	Cost Center	Project	Task`

The timestamp and parameters are tab-separated.

### Running the app

The app starts tracking time automatically when launched or manually via menu and will keep tracking time until stopped via menu.

Add this to your login items to have it always loaded and running.

When running, it will pause tracking if:

1. The device is put to sleep. It will resume when the device wakes.
2. When the screen is locked during lunch time (12h - 14h).

To generate a report, simply select the option from the menu. The report parameters can be configured via Settings. The following parameters are configurable:

* Project Manager
* Cost Center
* Project
* Task
* Show Totals: if enabled, the report will contain daily and weekly totals (this will render the report invalid, you need to manually edit it to remove these lines)

Upon first launch, the default parameters for the template will be loaded from `default_report_data.plist`.

### Questions and issues

Please take a look at the source code and solve them 🙂
