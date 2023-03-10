#ifndef _PLATFORMAMIGA_H
#define _PLATFORMAMIGA_H

#define PlatformClass PlatformAmiga

#include "Platform.h"

struct BitMap;
struct Screen;
struct Window;
struct Interrupt;
struct IOAudio;
struct MsgPort;
struct BitMap;
struct SimpleSprite;
struct UCopList;
class Palette;

class PlatformAmiga : public Platform {
public:
    PlatformAmiga();
    ~PlatformAmiga();

    virtual uint8_t* standardControls() const;
    virtual void setInterrupt(void (*interrupt)(void));
    virtual void show();
    virtual int framesPerSecond();
    virtual uint8_t readKeyboard();
    virtual void keyRepeat();
    virtual void clearKeyBuffer();
    virtual bool isKeyOrJoystickPressed(bool gamepad);
    virtual uint16_t readJoystick(bool gamepad);
    virtual void loadMap(Map map, uint8_t* destination);
    virtual uint8_t* loadTileset();
#ifdef PLATFORM_IMAGE_SUPPORT
    virtual void displayImage(Image image);
#endif
    virtual void generateTiles(uint8_t* tileData, uint8_t* tileAttributes);
#ifndef PLATFORM_IMAGE_BASED_TILES
    virtual void updateTiles(uint8_t* tileData, uint8_t* tiles, uint8_t numTiles);
#endif
    virtual void renderTile(uint8_t tile, uint16_t x, uint16_t y, uint8_t variant, bool transparent);
    virtual void renderTiles(uint8_t backgroundTile, uint8_t foregroundTile, uint16_t x, uint16_t y, uint8_t backgroundVariant, uint8_t foregroundVariant);
#ifdef PLATFORM_IMAGE_SUPPORT
    virtual void renderItem(uint8_t item, uint16_t x, uint16_t y);
    virtual void renderKey(uint8_t key, uint16_t x, uint16_t y);
    virtual void renderHealth(uint8_t health, uint16_t x, uint16_t y);
    virtual void renderFace(uint8_t face, uint16_t x, uint16_t y);
#endif
#ifdef PLATFORM_LIVE_MAP_SUPPORT
    virtual void renderLiveMap(uint8_t* map);
    virtual void renderLiveMapTile(uint8_t* map, uint8_t x, uint8_t y);
    virtual void renderLiveMapUnits(uint8_t* map, uint8_t* unitTypes, uint8_t* unitX, uint8_t* unitY, uint8_t playerColor, bool showRobots);
#endif
#ifdef PLATFORM_CURSOR_SUPPORT
    virtual void showCursor(uint16_t x, uint16_t y);
    virtual void hideCursor();
#ifdef PLATFORM_CURSOR_SHAPE_SUPPORT
    virtual void setCursorShape(CursorShape shape);
#endif
#endif
    virtual void copyRect(uint16_t sourceX, uint16_t sourceY, uint16_t destinationX, uint16_t destinationY, uint16_t width, uint16_t height);
    virtual void clearRect(uint16_t x, uint16_t y, uint16_t width, uint16_t height);
    virtual void fillRect(uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t color);
#ifdef PLATFORM_HARDWARE_BASED_SHAKE_SCREEN
    virtual void shakeScreen();
    virtual void stopShakeScreen();
#endif
#ifdef PLATFORM_FADE_SUPPORT
    virtual void startFadeScreen(uint16_t color, uint16_t intensity);
    virtual void fadeScreen(uint16_t intensity, bool immediate);
    virtual void stopFadeScreen();
#endif
    virtual void writeToScreenMemory(address_t address, uint8_t value);
    virtual void writeToScreenMemory(address_t address, uint8_t value, uint8_t color, uint8_t yOffset);
#ifdef PLATFORM_MODULE_BASED_AUDIO
    virtual void loadModule(Module module);
    virtual void playModule(Module module);
    virtual void pauseModule();
    virtual void stopModule();
    virtual void playSample(uint8_t sample);
    virtual void stopSample();
#else
    virtual void playNote(uint8_t note);
    virtual void stopNote();
#endif
    virtual void renderFrame(bool waitForNextFrame);
    virtual void waitForScreenMemoryAccess();
#ifdef INACTIVITY_TIMEOUT_INTRO
    virtual void setHighlightedMenuRow(uint16_t row);
#endif

private:
    __saveds void runVerticalBlankInterrupt();
    __asm static void verticalBlankInterruptServer();
    void (*interrupt)(void);
    uint32_t load(const char* filename, uint8_t* destination, uint32_t size);
#ifdef PLATFORM_PRELOAD_SUPPORT
    void preloadAssets();
#endif
#ifdef PLATFORM_MODULE_BASED_AUDIO
    void undeltaSamples(uint8_t* module, uint32_t moduleSize);
    void setSampleData(uint8_t* module);
#endif
#ifdef PLATFORM_SPRITE_SUPPORT
    void renderSprite(uint8_t sprite, uint16_t x, uint16_t y);
#endif
#ifdef PLATFORM_IMAGE_BASED_TILES
    void renderAnimTile(uint8_t animTile, uint16_t x, uint16_t y);
#endif
#ifdef PLATFORM_LIVE_MAP_SUPPORT
    __asm void renderLiveMapTiles(register __a1 uint8_t* map);
//    void renderLiveMapTiles(uint8_t* map);
#endif
    __asm static uint16_t readCD32Pad();
    __asm static void enableLowpassFilter();
    __asm static void disableLowpassFilter();
#ifdef INACTIVITY_TIMEOUT_INTRO
    uint16_t* getUserCopperlist();
    void animate();
    void attract();
#endif
    int framesPerSecond_;
    uint32_t clock;
    uint32_t originalDirectoryLock;
    BitMap* screenBitmap;
    Screen* screen;
    Window* window;
    Interrupt* verticalBlankInterrupt;
    uint8_t* chipMemory;
    uint8_t* screenPlanes;
#ifndef PLATFORM_IMAGE_BASED_TILES
    uint8_t* tilesPlanes;
#endif
    uint8_t* tilesMask;
    uint8_t* combinedTilePlanes;
#ifdef PLATFORM_MODULE_BASED_AUDIO
    uint8_t* moduleData;
    Module loadedModule;
#endif
#ifdef PLATFORM_IMAGE_SUPPORT
    Image loadedImage;
#endif
    IOAudio* ioAudio;
    MsgPort* messagePort;
    BitMap* tilesBitMap;
#ifdef PLATFORM_IMAGE_SUPPORT
    BitMap* facesBitMap;
    BitMap* itemsBitMap;
    BitMap* healthBitMap;
#endif
#ifdef PLATFORM_CURSOR_SUPPORT
    SimpleSprite* cursorSprite1;
    SimpleSprite* cursorSprite2;
#endif
    Palette* palette;
    uint8_t* loadBuffer;
#ifdef PLATFORM_PRELOAD_SUPPORT
    uint8_t* preloadedAssetBuffer;
    uint8_t* preloadedAssets[24];
    uint32_t preloadedAssetLengths[24];
#endif
#if defined(INACTIVITY_TIMEOUT_INTRO) || defined(INACTIVITY_TIMEOUT_GAME)
    uint16_t framesIdle;
#endif
#ifdef INACTIVITY_TIMEOUT_INTRO
    UCopList* userCopperList;
    Palette* highlightedMenuRowPalette;
    Palette* explosionPalette;
    int8_t highlightedMenuRowFadeDelta;
    int8_t explosionFadeDelta;
    uint8_t explosionFadeWait;
    uint8_t attractImageX;
    uint8_t attractImageY;
#endif
    uint16_t bplcon1DefaultValue;
    uint8_t shakeStep;
    uint8_t keyToReturn;
    uint8_t downKey;
    uint8_t shift;
    uint16_t joystickStateToReturn;
    uint16_t joystickState;
    uint16_t pendingState;
    bool filterState;
#ifdef PLATFORM_MODULE_BASED_AUDIO
    uint8_t effectChannel;
#endif
};

#endif
