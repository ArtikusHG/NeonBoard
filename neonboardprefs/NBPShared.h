#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"

NSDictionary *prefsDict();
void writePrefsDict(NSDictionary *dict);

UIImage *iconForCellFromIcon(UIImage *icon, CGSize size);

void respring();
