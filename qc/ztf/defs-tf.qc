
.float lefty;       // qwtf hook
.float maxspeed;    // qwtf
.entity oldenemy;   // qwtf
.float search_time; // qwtf
.void() th_melee;   // qwtf
.void() th_missile; // qwtf
vector vector_null; // qwtf
.float		cnt2;			// qwtf misc flag

//
// sentry
//
.float waitmin;
.float waitmax;

//
// TF unknown
//
.float volume;
.float oldheight;
.entity movetarget;
.float distance;

float(float f) sqrt = #62; // qwtf

void(string str) tokanize = #84; // tokanize text
float() argc = #85;              // returns number of tokens
string(float num) argv = #86;    // returns token for the given number
string (string str, float start, float len) substr = #88;
string (string str1, string str2) strcat = #89;
float (string str) strlen = #90;
float (string str) str2byte = #91;
float (string str) str2short = #92;
string (string str , float size) newstr = #93;
void (string str) freestr = #94;
string (string str) readcmd = #96;                               // executes command on server, but result is returned by this function instead of writing to the console
string(string str, string substr) strstr = #98;                  // searches for substring in str, returns pointer to it or "" if not found
void(string logname, float console, string text) logname = #100; // prints text to file 'logname', if console is non-zero, prints to the server console as well
void(entity cl, string text) redirectcmd = #101;                 // executes string on the console and redirects output to client (eg redirect(self, "status"))
void() calltimeofday = #102;                                     // force server to call mod function timeofday
float (string s) findmap = #104;
float(entity client, float level, float range, float start, float style, float footer) listmaps = #105;
string(float id) findmapname = #106;

