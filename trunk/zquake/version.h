// version.h

#define	QW_VERSION	2.40
#define PROGRAM_VERSION	"0.15dev"

// #define RELEASE_VERSION

#ifdef _WIN32
#define QW_PLATFORM	"Win32"
#else 
#define QW_PLATFORM	"Linux"
#endif

#ifdef GLQUAKE
#define QW_RENDERER	"GL"
#else
#define QW_RENDERER "Soft"
#endif


int build_number (void);
void CL_Version_f (void);
char *VersionString (void);
