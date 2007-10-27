//___________________________________________________________________________________________________________nFO
// "vid_osx.h" - MacOS X Video driver
//
// Written by:	Axel 'awe' Wefers		[mailto:awe@fruitz-of-dojo.de].
//		�2001-2002 Fruitz Of Dojo 	[http://www.fruitz-of-dojo.de].
//
// Quake� is copyrighted by id software	[http://www.idsoftware.com].
//
//_______________________________________________________________________________________________________dEFINES

#pragma mark =Defines=

#define VID_MAX_DISPLAYS 		100
#define VID_FADE_DURATION		1.0f

#define VID_GAMMA_TABLE_SIZE		256
#define VID_FONT_WIDTH			8
#define	VID_FONT_HEIGHT			8

#pragma mark -

//______________________________________________________________________________________________________tYPEDEFS

#pragma mark =TypeDefs=

typedef struct 		{
                                CGDirectDisplayID	displayID;
                                CGGammaValue		component[9];
                        }	vid_gamma_t;

typedef struct		{
                                CGTableCount		count;
                                CGGammaValue		red[VID_GAMMA_TABLE_SIZE];
                                CGGammaValue		green[VID_GAMMA_TABLE_SIZE];
                                CGGammaValue		blue[VID_GAMMA_TABLE_SIZE];
                        }	vid_gammatable_t;

#pragma mark -

//_____________________________________________________________________________________________________vARIABLES

#pragma mark =Variables=

extern  cvar_t			_windowed_mouse;

extern  NSWindow *		gVidWindow;
extern  BOOL			gVidIsMinimized,
                                gVidDisplayFullscreen,
                                gVidFadeAllDisplays;
extern  UInt32			gVidDisplay;
extern  CGDirectDisplayID  	gVidDisplayList[VID_MAX_DISPLAYS];
extern  CGDisplayCount		gVidDisplayCount;
extern	float			gVidWindowPosX,
                                gVidWindowPosY;
extern	vid_gamma_t *		gVshOriginalGamma;

#if defined (GLQUAKE)

extern  NSDictionary *		gVidDisplayMode;
extern	SInt32	                gGLMultiSamples;
extern	vid_gammatable_t *	gVshGammaTable;

#endif /* GLQUAKE */
        
//___________________________________________________________________________________________fUNCTION_pROTOTYPES

#pragma mark =Function Prototypes=

extern void	M_Menu_Options_f (void);
extern void	M_Print (int, int, char *);
extern void	M_PrintWhite (int, int, char *);
extern void	M_DrawCharacter (int, int, int);
extern void	M_DrawTransPic (int, int, mpic_t *);
extern void	M_DrawPic (int, int, mpic_t *);

void GL_SetMiniWindowBuffer (void);

#if defined (GLQUAKE)

BOOL	GL_CheckARBMultisampleExtension (CGDirectDisplayID theDisplay);

#else

BOOL	VID_HideFullscreen (BOOL);

#endif /* GLQUAKE */

BOOL	VSH_CaptureDisplays (BOOL theCaptureAllDisplays);
BOOL	VSH_ReleaseDisplays (BOOL theCaptureAllDisplays);
void	VSH_FadeGammaOut (BOOL theFadeOnAllDisplays, float theDuration);
void	VSH_FadeGammaIn (BOOL theFadeOnAllDisplays, float theDuration);
void	VSH_FadeGammaRelease (void);

//___________________________________________________________________________________________________________eOF
