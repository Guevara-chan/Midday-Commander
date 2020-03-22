# 
#   raylib - A simple and easy-to-use library to enjoy videogames programming (www.raylib.com)
# 
#   FEATURES:
#       - NO external dependencies, all required libraries included with raylib
#       - Multiplatform: Windows, Linux, FreeBSD, OpenBSD, NetBSD, DragonFly, MacOS, UWP, Android, Raspberry Pi, HTML5.
#       - Written in plain C code (C99) in PascalCase/camelCase notation
#       - Hardware accelerated with OpenGL (1.1, 2.1, 3.3 or ES2 - choose at compile)
#       - Unique OpenGL abstraction layer (usable as standalone module): [rlgl]
#       - Powerful fonts module (XNA SpriteFonts, BMFonts, TTF)
#       - Outstanding texture formats support, including compressed formats (DXT, ETC, ASTC)
#       - Full 3d support for 3d Shapes, Models, Billboards, Heightmaps and more!
#       - Flexible Materials system, supporting classic maps and PBR maps
#       - Skeletal Animation support (CPU bones-based animation)
#       - Shaders support, including Model shaders and Postprocessing shaders
#       - Powerful math module for Vector, Matrix and Quaternion operations: [raymath]
#       - Audio loading and playing with streaming support (WAV, OGG, MP3, FLAC, XM, MOD)
#       - VR stereo rendering with configurable HMD device parameters
#       - Bindings to multiple programming languages available!
# 
#   NOTES:
#       One custom font is loaded by default when InitWindow() [core]
#       If using OpenGL 3.3 or ES2, one default shader is loaded automatically (internally defined) [rlgl]
#       If using OpenGL 3.3 or ES2, several vertex buffers (VAO/VBO) are created to manage lines-triangles-quads
# 
#   DEPENDENCIES (included):
#       [core] rglfw (github.com/glfw/glfw) for window/context management and input (only PLATFORM_DESKTOP)
#       [rlgl] glad (github.com/Dav1dde/glad) for OpenGL 3.3 extensions loading (only PLATFORM_DESKTOP)
#       [raudio] miniaudio (github.com/dr-soft/miniaudio) for audio device/context management
# 
#   OPTIONAL DEPENDENCIES (included):
#       [core] rgif (Charlie Tangora, Ramon Santamaria) for GIF recording
#       [textures] stb_image (Sean Barret) for images loading (BMP, TGA, PNG, JPEG, HDR...)
#       [textures] stb_image_write (Sean Barret) for image writting (BMP, TGA, PNG, JPG)
#       [textures] stb_image_resize (Sean Barret) for image resizing algorithms
#       [textures] stb_perlin (Sean Barret) for Perlin noise image generation
#       [text] stb_truetype (Sean Barret) for ttf fonts loading
#       [text] stb_rect_pack (Sean Barret) for rectangles packing
#       [models] par_shapes (Philip Rideout) for parametric 3d shapes generation
#       [models] tinyobj_loader_c (Syoyo Fujita) for models loading (OBJ, MTL)
#       [models] cgltf (Johannes Kuhlmann) for models loading (glTF)
#       [raudio] stb_vorbis (Sean Barret) for OGG audio loading
#       [raudio] dr_flac (David Reid) for FLAC audio file loading
#       [raudio] dr_mp3 (David Reid) for MP3 audio file loading
#       [raudio] jar_xm (Joshua Reisenauer) for XM audio module loading
#       [raudio] jar_mod (Joshua Reisenauer) for MOD audio module loading
# 
# 
#   LICENSE: zlib/libpng
# 
#   raylib is licensed under an unmodified zlib/libpng license, which is an OSI-certified,
#   BSD-like license that allows static linking with closed source software:
# 
#   Copyright (c) 2013-2020 Ramon Santamaria (@raysan5)
# 
#   This software is provided "as-is", without any express or implied warranty. In no event
#   will the authors be held liable for any damages arising from the use of this software.
# 
#   Permission is granted to anyone to use this software for any purpose, including commercial
#   applications, and to alter it and redistribute it freely, subject to the following restrictions:
# 
#     1. The origin of this software must not be misrepresented; you must not claim that you
#     wrote the original software. If you use this software in a product, an acknowledgment
#     in the product documentation would be appreciated but is not required.
# 
#     2. Altered source versions must be plainly marked as such, and must not be misrepresented
#     as being the original software.
# 
#     3. This notice may not be removed or altered from any source distribution.
# 
converter int2in32* (self: int): int32 = self.int32
const LEXT* = when defined(windows):".dll"
elif defined(macosx):               ".dylib"
else:                               ".so"
{.pragma: RLAPI, cdecl, discardable, dynlib: "libraylib" & LEXT.}
# ----------------------------------------------------------------------------------
# Some basic Defines
# ----------------------------------------------------------------------------------
template DEG2RAD*(): auto = (PI/180.0f)
template RAD2DEG*(): auto = (180.0f/PI)
template MAX_TOUCH_POINTS*(): auto = 10
# Allow custom memory allocators
# NOTE: MSC C++ compiler does not support compound literals (C99 feature)
# Plain structures in C++ (without constructors) can be initialized from { } initializers.
# Some Basic Colors
# NOTE: Custom raylib color palette for amazing visuals on WHITE background
template LIGHTGRAY*(): auto = Color(r: 200, g: 200, b: 200, a: 255) # Light Gray
template GRAY*(): auto = Color(r: 130, g: 130, b: 130, a: 255) # Gray
template DARKGRAY*(): auto = Color(r: 80, g: 80, b: 80, a: 255) # Dark Gray
template YELLOW*(): auto = Color(r: 253, g: 249, b: 0, a: 255) # Yellow
template GOLD*(): auto = Color(r: 255, g: 203, b: 0, a: 255) # Gold
template ORANGE*(): auto = Color(r: 255, g: 161, b: 0, a: 255) # Orange
template PINK*(): auto = Color(r: 255, g: 109, b: 194, a: 255) # Pink
template RED*(): auto = Color(r: 230, g: 41, b: 55, a: 255) # Red
template MAROON*(): auto = Color(r: 190, g: 33, b: 55, a: 255) # Maroon
template GREEN*(): auto = Color(r: 0, g: 228, b: 48, a: 255) # Green
template LIME*(): auto = Color(r: 0, g: 158, b: 47, a: 255) # Lime
template DARKGREEN*(): auto = Color(r: 0, g: 117, b: 44, a: 255) # Dark Green
template SKYBLUE*(): auto = Color(r: 102, g: 191, b: 255, a: 255) # Sky Blue
template BLUE*(): auto = Color(r: 0, g: 121, b: 241, a: 255) # Blue
template DARKBLUE*(): auto = Color(r: 0, g: 82, b: 172, a: 255) # Dark Blue
template PURPLE*(): auto = Color(r: 200, g: 122, b: 255, a: 255) # Purple
template VIOLET*(): auto = Color(r: 135, g: 60, b: 190, a: 255) # Violet
template DARKPURPLE*(): auto = Color(r: 112, g: 31, b: 126, a: 255) # Dark Purple
template BEIGE*(): auto = Color(r: 211, g: 176, b: 131, a: 255) # Beige
template BROWN*(): auto = Color(r: 127, g: 106, b: 79, a: 255) # Brown
template DARKBROWN*(): auto = Color(r: 76, g: 63, b: 47, a: 255) # Dark Brown
template WHITE*(): auto = Color(r: 255, g: 255, b: 255, a: 255) # White
template BLACK*(): auto = Color(r: 0, g: 0, b: 0, a: 255) # Black
template BLANK*(): auto = Color(r: 0, g: 0, b: 0, a: 0) # Blank (Transparent)
template MAGENTA*(): auto = Color(r: 255, g: 0, b: 255, a: 255) # Magenta
template RAYWHITE*(): auto = Color(r: 245, g: 245, b: 245, a: 255) # My own White (raylib logo)
# Temporal hack to avoid breaking old codebases using
# deprecated raylib implementation of these functions
template FormatText*(): auto = TextFormat
template SubText*(): auto = TextSubtext
template ShowWindow*(): auto = UnhideWindow
# ----------------------------------------------------------------------------------
# Structures Definition
# ----------------------------------------------------------------------------------
# Boolean type
# Vector2 type
type Vector2* = object
    x*: float32 
    y*: float32 
# Vector3 type
type Vector3* = object
    x*: float32 
    y*: float32 
    z*: float32 
# Vector4 type
type Vector4* = object
    x*: float32 
    y*: float32 
    z*: float32 
    w*: float32 
# Quaternion type, same as Vector4
type Quaternion* = Vector4
# Matrix type (OpenGL style 4x4 - right handed, column major)
type Matrix* = object
    m0*, m4*, m8*, m12*: float32 
    m1*, m5*, m9*, m13*: float32 
    m2*, m6*, m10*, m14*: float32 
    m3*, m7*, m11*, m15*: float32 
# Color type, RGBA (32bit)
type Color* = object
    r*: uint8 
    g*: uint8 
    b*: uint8 
    a*: uint8 
# Rectangle type
type Rectangle* = object
    x*: float32 
    y*: float32 
    width*: float32 
    height*: float32 
# Image type, bpp always RGBA (32bit)
# NOTE: Data stored in CPU memory (RAM)
type Image* = object
    data*: pointer # Image raw data
    width*: int32 # Image base width
    height*: int32 # Image base height
    mipmaps*: int32 # Mipmap levels, 1 by default
    format*: int32 # Data format (PixelFormat type)
# Texture2D type
# NOTE: Data stored in GPU memory
type Texture2D* = object
    id*: uint32 # OpenGL texture id
    width*: int32 # Texture base width
    height*: int32 # Texture base height
    mipmaps*: int32 # Mipmap levels, 1 by default
    format*: int32 # Data format (PixelFormat type)
# Texture type, same as Texture2D
type Texture* = Texture2D
# TextureCubemap type, actually, same as Texture2D
type TextureCubemap* = Texture2D
# RenderTexture2D type, for texture rendering
type RenderTexture2D* = object
    id*: uint32 # OpenGL Framebuffer Object (FBO) id
    texture*: Texture2D # Color buffer attachment texture
    depth*: Texture2D # Depth buffer attachment texture
    depthTexture*: bool # Track if depth attachment is a texture or renderbuffer
# RenderTexture type, same as RenderTexture2D
type RenderTexture* = RenderTexture2D
# N-Patch layout info
type NPatchInfo* = object
    sourceRec*: Rectangle # Region in the texture
    left*: int32 # left border offset
    top*: int32 # top border offset
    right*: int32 # right border offset
    bottom*: int32 # bottom border offset
    typex*: int32 # layout of the n-patch: 3x3, 1x3 or 3x1
# Font character info
type CharInfo* = object
    value*: int32 # Character value (Unicode)
    offsetX*: int32 # Character offset X when drawing
    offsetY*: int32 # Character offset Y when drawing
    advanceX*: int32 # Character advance position X
    image*: Image # Character image data
# Font type, includes texture and charSet array data
type Font* = object
    baseSize*: int32 # Base size (default chars height)
    charsCount*: int32 # Number of characters
    texture*: Texture2D # Characters texture atlas
    recs*: ptr Rectangle # Characters rectangles in texture
    chars*: ptr CharInfo # Characters info data
template SpriteFont*(): auto = Font
# Camera type, defines a camera position/orientation in 3d space
type Camera3D* = object
    position*: Vector3 # Camera position
    target*: Vector3 # Camera target it looks-at
    up*: Vector3 # Camera up vector (rotation over its axis)
    fovy*: float32 # Camera field-of-view apperture in Y (degrees) in perspective, used as near plane width in orthographic
    typex*: int32 # Camera type, defines projection type: CAMERA_PERSPECTIVE or CAMERA_ORTHOGRAPHIC
type Camera* = Camera3D
# Camera2D type, defines a 2d camera
type Camera2D* = object
    offset*: Vector2 # Camera offset (displacement from target)
    target*: Vector2 # Camera target (rotation and zoom origin)
    rotation*: float32 # Camera rotation in degrees
    zoom*: float32 # Camera zoom (scaling), should be 1.0f by default
# Vertex data definning a mesh
# NOTE: Data stored in CPU memory (and GPU)
type Mesh* = object
    vertexCount*: int32 # Number of vertices stored in arrays
    triangleCount*: int32 # Number of triangles stored (indexed or not)
    vertices*: float32 # Vertex position (XYZ - 3 components per vertex) (shader-location = 0)
    texcoords*: float32 # Vertex texture coordinates (UV - 2 components per vertex) (shader-location = 1)
    texcoords2*: float32 # Vertex second texture coordinates (useful for lightmaps) (shader-location = 5)
    normals*: float32 # Vertex normals (XYZ - 3 components per vertex) (shader-location = 2)
    tangents*: float32 # Vertex tangents (XYZW - 4 components per vertex) (shader-location = 4)
    colors*: uint8 # Vertex colors (RGBA - 4 components per vertex) (shader-location = 3)
    indices*: uint16 # Vertex indices (in case vertex data comes indexed)
    animVertices*: float32 # Animated vertex positions (after bones transformations)
    animNormals*: float32 # Animated normals (after bones transformations)
    boneIds*: pointer # Vertex bone ids, up to 4 bones influence by vertex (skinning)
    boneWeights*: float32 # Vertex bone weight, up to 4 bones influence by vertex (skinning)
    vaoId*: uint32 # OpenGL Vertex Array Object id
    vboId*: uint32 # OpenGL Vertex Buffer Objects id (default vertex data)
# Shader type (generic)
type Shader* = object
    id*: uint32 # Shader program id
    locs*: pointer # Shader locations array (MAX_SHADER_LOCATIONS)
# Material texture map
type MaterialMap* = object
    texture*: Texture2D # Material map texture
    color*: Color # Material map color
    value*: float32 # Material map value
# Material type (generic)
type Material* = object
    shader*: Shader # Material shader
    maps*: ptr MaterialMap # Material maps array (MAX_MATERIAL_MAPS)
    params*: float32 # Material generic parameters (if required)
# Transformation properties
type Transform* = object
    translation*: Vector3 # Translation
    rotation*: Quaternion # Rotation
    scale*: Vector3 # Scale
# Bone information
type BoneInfo* = object
    name*: array[0..31, char] # Bone name
    parent*: int32 # Bone parent
# Model type
type Model* = object
    transform*: Matrix # Local transform matrix
    meshCount*: int32 # Number of meshes
    meshes*: ptr Mesh # Meshes array
    materialCount*: int32 # Number of materials
    materials*: ptr Material # Materials array
    meshMaterial*: pointer # Mesh material number
    boneCount*: int32 # Number of bones
    bones*: ptr BoneInfo # Bones information (skeleton)
    bindPose*: ptr Transform # Bones base transformation (pose)
# Model animation
type ModelAnimation* = object
    boneCount*: int32 # Number of bones
    bones*: ptr BoneInfo # Bones information (skeleton)
    frameCount*: int32 # Number of animation frames
    framePoses*: ptr Transform # Poses array by frame
# Ray type (useful for raycast)
type Ray* = object
    position*: Vector3 # Ray position (origin)
    direction*: Vector3 # Ray direction
# Raycast hit information
type RayHitInfo* = object
    hit*: bool # Did the ray hit something?
    distance*: float32 # Distance to nearest hit
    position*: Vector3 # Position of nearest hit
    normal*: Vector3 # Surface normal of hit
# Bounding box type
type BoundingBox* = object
    min*: Vector3 # Minimum vertex box-corner
    max*: Vector3 # Maximum vertex box-corner
# Wave type, defines audio wave data
type Wave* = object
    sampleCount*: uint32 # Total number of samples
    sampleRate*: uint32 # Frequency (samples per second)
    sampleSize*: uint32 # Bit depth (bits per sample): 8, 16, 32 (24 not supported)
    channels*: uint32 # Number of channels (1-mono, 2-stereo)
    data*: pointer # Buffer data pointer
type rAudioBuffer* = object
# Audio stream type
# NOTE: Useful to create custom audio streams not bound to a specific file
type AudioStream* = object
    sampleRate*: uint32 # Frequency (samples per second)
    sampleSize*: uint32 # Bit depth (bits per sample): 8, 16, 32 (24 not supported)
    channels*: uint32 # Number of channels (1-mono, 2-stereo)
    buffer*: ptr rAudioBuffer # Pointer to internal data used by the audio system
# Sound source type
type Sound* = object
    sampleCount*: uint32 # Total number of samples
    stream*: AudioStream # Audio stream
# Music stream type (audio file streaming from memory)
# NOTE: Anything longer than ~10 seconds should be streamed
type Music* = object
    ctxType*: int32 # Type of music context (audio filetype)
    ctxData*: pointer # Audio context data, depends on type
    sampleCount*: uint32 # Total number of samples
    loopCount*: uint32 # Loops count (times music will play), 0 means infinite loop
    stream*: AudioStream # Audio stream
# Head-Mounted-Display device parameters
type VrDeviceInfo* = object
    hResolution*: int32 # HMD horizontal resolution in pixels
    vResolution*: int32 # HMD vertical resolution in pixels
    hScreenSize*: float32 # HMD horizontal size in meters
    vScreenSize*: float32 # HMD vertical size in meters
    vScreenCenter*: float32 # HMD screen center in meters
    eyeToScreenDistance*: float32 # HMD distance between eye and display in meters
    lensSeparationDistance*: float32 # HMD lens separation distance in meters
    interpupillaryDistance*: float32 # HMD IPD (distance between pupils) in meters
    lensDistortionValues*: array[0..3, float32] # HMD lens distortion constant parameters
    chromaAbCorrection*: array[0..3, float32] # HMD chromatic aberration correction parameters
# ----------------------------------------------------------------------------------
# Enumerators Definition
# ----------------------------------------------------------------------------------
# System config flags
# NOTE: Used for bit masks
type ConfigFlag* = enum 
    FLAG_RESERVED           = 1 # Reserved
    FLAG_FULLSCREEN_MODE    = 2 # Set to run program in fullscreen
    FLAG_WINDOW_RESIZABLE   = 4 # Set to allow resizable window
    FLAG_WINDOW_UNDECORATED = 8 # Set to disable window decoration (frame and buttons)
    FLAG_WINDOW_TRANSPARENT = 16 # Set to allow transparent window
    FLAG_MSAA_4X_HINT       = 32 # Set to try enabling MSAA 4X
    FLAG_VSYNC_HINT         = 64 # Set to try enabling V-Sync on GPU
    FLAG_WINDOW_HIDDEN      = 128 # Set to create the window initially hidden
    FLAG_WINDOW_ALWAYS_RUN  = 256 # Set to allow windows running while minimized
converter ConfigFlag2int32* (self: ConfigFlag): int32 = self.int32 
# Trace log type
type TraceLogType* = enum 
    LOG_ALL = 0 # Display all logs
    LOG_TRACE 
    LOG_DEBUG 
    LOG_INFO 
    LOG_WARNING 
    LOG_ERROR 
    LOG_FATAL 
    LOG_NONE # Disable logging
converter TraceLogType2int32* (self: TraceLogType): int32 = self.int32 
# Keyboard keys
type KeyboardKey* = enum 
    KEY_SPACE           = 32 
    KEY_APOSTROPHE      = 39 
    KEY_COMMA           = 44 
    KEY_MINUS           = 45 
    KEY_PERIOD          = 46 
    KEY_SLASH           = 47 
    KEY_ZERO            = 48 
    KEY_ONE             = 49 
    KEY_TWO             = 50 
    KEY_THREE           = 51 
    KEY_FOUR            = 52 
    KEY_FIVE            = 53 
    KEY_SIX             = 54 
    KEY_SEVEN           = 55 
    KEY_EIGHT           = 56 
    KEY_NINE            = 57 
    KEY_SEMICOLON       = 59 
    KEY_EQUAL           = 61 
    KEY_A               = 65 
    KEY_B               = 66 
    KEY_C               = 67 
    KEY_D               = 68 
    KEY_E               = 69 
    KEY_F               = 70 
    KEY_G               = 71 
    KEY_H               = 72 
    KEY_I               = 73 
    KEY_J               = 74 
    KEY_K               = 75 
    KEY_L               = 76 
    KEY_M               = 77 
    KEY_N               = 78 
    KEY_O               = 79 
    KEY_P               = 80 
    KEY_Q               = 81 
    KEY_R               = 82 
    KEY_S               = 83 
    KEY_T               = 84 
    KEY_U               = 85 
    KEY_V               = 86 
    KEY_W               = 87 
    KEY_X               = 88 
    KEY_Y               = 89 
    KEY_Z               = 90 
    KEY_LEFT_BRACKET    = 91 
    KEY_BACKSLASH       = 92 
    KEY_RIGHT_BRACKET   = 93 
    KEY_GRAVE           = 96 
    KEY_ESCAPE          = 256 
    KEY_ENTER           = 257 
    KEY_TAB             = 258 
    KEY_BACKSPACE       = 259 
    KEY_INSERT          = 260 
    KEY_DELETE          = 261 
    KEY_RIGHT           = 262 
    KEY_LEFT            = 263 
    KEY_DOWN            = 264 
    KEY_UP              = 265 
    KEY_PAGE_UP         = 266 
    KEY_PAGE_DOWN       = 267 
    KEY_HOME            = 268 
    KEY_END             = 269 
    KEY_CAPS_LOCK       = 280 
    KEY_SCROLL_LOCK     = 281 
    KEY_NUM_LOCK        = 282 
    KEY_PRINT_SCREEN    = 283 
    KEY_PAUSE           = 284 
    KEY_F1              = 290 
    KEY_F2              = 291 
    KEY_F3              = 292 
    KEY_F4              = 293 
    KEY_F5              = 294 
    KEY_F6              = 295 
    KEY_F7              = 296 
    KEY_F8              = 297 
    KEY_F9              = 298 
    KEY_F10             = 299 
    KEY_F11             = 300 
    KEY_F12             = 301 
    KEY_KP_0            = 320 
    KEY_KP_1            = 321 
    KEY_KP_2            = 322 
    KEY_KP_3            = 323 
    KEY_KP_4            = 324 
    KEY_KP_5            = 325 
    KEY_KP_6            = 326 
    KEY_KP_7            = 327 
    KEY_KP_8            = 328 
    KEY_KP_9            = 329 
    KEY_KP_DECIMAL      = 330 
    KEY_KP_DIVIDE       = 331 
    KEY_KP_MULTIPLY     = 332 
    KEY_KP_SUBTRACT     = 333 
    KEY_KP_ADD          = 334 
    KEY_KP_ENTER        = 335 
    KEY_KP_EQUAL        = 336 
    KEY_LEFT_SHIFT      = 340 
    KEY_LEFT_CONTROL    = 341 
    KEY_LEFT_ALT        = 342 
    KEY_LEFT_SUPER      = 343 
    KEY_RIGHT_SHIFT     = 344 
    KEY_RIGHT_CONTROL   = 345 
    KEY_RIGHT_ALT       = 346 
    KEY_RIGHT_SUPER     = 347 
    KEY_KB_MENU         = 348 
converter KeyboardKey2int32* (self: KeyboardKey): int32 = self.int32 
# Android buttons
type AndroidButton* = enum 
    KEY_BACK            = 4 
    KEY_VOLUME_UP       = 24 
    KEY_VOLUME_DOWN     = 25 
    KEY_MENU            = 82 
converter AndroidButton2int32* (self: AndroidButton): int32 = self.int32 
# Mouse buttons
type MouseButton* = enum 
    MOUSE_LEFT_BUTTON   = 0 
    MOUSE_RIGHT_BUTTON  = 1 
    MOUSE_MIDDLE_BUTTON = 2 
converter MouseButton2int32* (self: MouseButton): int32 = self.int32 
# Gamepad number
type GamepadNumber* = enum 
    GAMEPAD_PLAYER1     = 0 
    GAMEPAD_PLAYER2     = 1 
    GAMEPAD_PLAYER3     = 2 
    GAMEPAD_PLAYER4     = 3 
converter GamepadNumber2int32* (self: GamepadNumber): int32 = self.int32 
# Gamepad Buttons
type GamepadButton* = enum 
    GAMEPAD_BUTTON_UNKNOWN = 0 
    GAMEPAD_BUTTON_LEFT_FACE_UP 
    GAMEPAD_BUTTON_LEFT_FACE_RIGHT 
    GAMEPAD_BUTTON_LEFT_FACE_DOWN 
    GAMEPAD_BUTTON_LEFT_FACE_LEFT 
    GAMEPAD_BUTTON_RIGHT_FACE_UP 
    GAMEPAD_BUTTON_RIGHT_FACE_RIGHT 
    GAMEPAD_BUTTON_RIGHT_FACE_DOWN 
    GAMEPAD_BUTTON_RIGHT_FACE_LEFT 
    GAMEPAD_BUTTON_LEFT_TRIGGER_1 
    GAMEPAD_BUTTON_LEFT_TRIGGER_2 
    GAMEPAD_BUTTON_RIGHT_TRIGGER_1 
    GAMEPAD_BUTTON_RIGHT_TRIGGER_2 
    GAMEPAD_BUTTON_MIDDLE_LEFT # PS3 Select
    GAMEPAD_BUTTON_MIDDLE # PS Button/XBOX Button
    GAMEPAD_BUTTON_MIDDLE_RIGHT # PS3 Start
    GAMEPAD_BUTTON_LEFT_THUMB 
    GAMEPAD_BUTTON_RIGHT_THUMB 
converter GamepadButton2int32* (self: GamepadButton): int32 = self.int32 
type GamepadAxis* = enum 
    GAMEPAD_AXIS_UNKNOWN = 0 
    GAMEPAD_AXIS_LEFT_X 
    GAMEPAD_AXIS_LEFT_Y 
    GAMEPAD_AXIS_RIGHT_X 
    GAMEPAD_AXIS_RIGHT_Y 
    GAMEPAD_AXIS_LEFT_TRIGGER # [1..-1] (pressure-level)
    GAMEPAD_AXIS_RIGHT_TRIGGER # [1..-1] (pressure-level)
converter GamepadAxis2int32* (self: GamepadAxis): int32 = self.int32 
# Shader location point type
type ShaderLocationIndex* = enum 
    LOC_VERTEX_POSITION = 0 
    LOC_VERTEX_TEXCOORD01 
    LOC_VERTEX_TEXCOORD02 
    LOC_VERTEX_NORMAL 
    LOC_VERTEX_TANGENT 
    LOC_VERTEX_COLOR 
    LOC_MATRIX_MVP 
    LOC_MATRIX_MODEL 
    LOC_MATRIX_VIEW 
    LOC_MATRIX_PROJECTION 
    LOC_VECTOR_VIEW 
    LOC_COLOR_DIFFUSE 
    LOC_COLOR_SPECULAR 
    LOC_COLOR_AMBIENT 
    LOC_MAP_ALBEDO # LOC_MAP_DIFFUSE
    LOC_MAP_METALNESS # LOC_MAP_SPECULAR
    LOC_MAP_NORMAL 
    LOC_MAP_ROUGHNESS 
    LOC_MAP_OCCLUSION 
    LOC_MAP_EMISSION 
    LOC_MAP_HEIGHT 
    LOC_MAP_CUBEMAP 
    LOC_MAP_IRRADIANCE 
    LOC_MAP_PREFILTER 
    LOC_MAP_BRDF 
converter ShaderLocationIndex2int32* (self: ShaderLocationIndex): int32 = self.int32 
template LOC_MAP_DIFFUSE*(): auto = LOC_MAP_ALBEDO
template LOC_MAP_SPECULAR*(): auto = LOC_MAP_METALNESS
# Shader uniform data types
type ShaderUniformDataType* = enum 
    UNIFORM_FLOAT = 0 
    UNIFORM_VEC2 
    UNIFORM_VEC3 
    UNIFORM_VEC4 
    UNIFORM_INT 
    UNIFORM_IVEC2 
    UNIFORM_IVEC3 
    UNIFORM_IVEC4 
    UNIFORM_SAMPLER2D 
converter ShaderUniformDataType2int32* (self: ShaderUniformDataType): int32 = self.int32 
# Material map type
type MaterialMapType* = enum 
    MAP_ALBEDO    = 0 # MAP_DIFFUSE
    MAP_METALNESS = 1 # MAP_SPECULAR
    MAP_NORMAL    = 2 
    MAP_ROUGHNESS = 3 
    MAP_OCCLUSION 
    MAP_EMISSION 
    MAP_HEIGHT 
    MAP_CUBEMAP # NOTE: Uses GL_TEXTURE_CUBE_MAP
    MAP_IRRADIANCE # NOTE: Uses GL_TEXTURE_CUBE_MAP
    MAP_PREFILTER # NOTE: Uses GL_TEXTURE_CUBE_MAP
    MAP_BRDF 
converter MaterialMapType2int32* (self: MaterialMapType): int32 = self.int32 
template MAP_DIFFUSE*(): auto = MAP_ALBEDO
template MAP_SPECULAR*(): auto = MAP_METALNESS
# Pixel formats
# NOTE: Support depends on OpenGL version and platform
type PixelFormat* = enum 
    UNCOMPRESSED_GRAYSCALE = 1 # 8 bit per pixel (no alpha)
    UNCOMPRESSED_GRAY_ALPHA # 8*2 bpp (2 channels)
    UNCOMPRESSED_R5G6B5 # 16 bpp
    UNCOMPRESSED_R8G8B8 # 24 bpp
    UNCOMPRESSED_R5G5B5A1 # 16 bpp (1 bit alpha)
    UNCOMPRESSED_R4G4B4A4 # 16 bpp (4 bit alpha)
    UNCOMPRESSED_R8G8B8A8 # 32 bpp
    UNCOMPRESSED_R32 # 32 bpp (1 channel - float)
    UNCOMPRESSED_R32G32B32 # 32*3 bpp (3 channels - float)
    UNCOMPRESSED_R32G32B32A32 # 32*4 bpp (4 channels - float)
    COMPRESSED_DXT1_RGB # 4 bpp (no alpha)
    COMPRESSED_DXT1_RGBA # 4 bpp (1 bit alpha)
    COMPRESSED_DXT3_RGBA # 8 bpp
    COMPRESSED_DXT5_RGBA # 8 bpp
    COMPRESSED_ETC1_RGB # 4 bpp
    COMPRESSED_ETC2_RGB # 4 bpp
    COMPRESSED_ETC2_EAC_RGBA # 8 bpp
    COMPRESSED_PVRT_RGB # 4 bpp
    COMPRESSED_PVRT_RGBA # 4 bpp
    COMPRESSED_ASTC_4x4_RGBA # 8 bpp
    COMPRESSED_ASTC_8x8_RGBA # 2 bpp
converter PixelFormat2int32* (self: PixelFormat): int32 = self.int32 
# Texture parameters: filter mode
# NOTE 1: Filtering considers mipmaps if available in the texture
# NOTE 2: Filter is accordingly set for minification and magnification
type TextureFilterMode* = enum 
    FILTER_POINT = 0 # No filter, just pixel aproximation
    FILTER_BILINEAR # Linear filtering
    FILTER_TRILINEAR # Trilinear filtering (linear with mipmaps)
    FILTER_ANISOTROPIC_4X # Anisotropic filtering 4x
    FILTER_ANISOTROPIC_8X # Anisotropic filtering 8x
    FILTER_ANISOTROPIC_16X # Anisotropic filtering 16x
converter TextureFilterMode2int32* (self: TextureFilterMode): int32 = self.int32 
# Cubemap layout type
type CubemapLayoutType* = enum 
    CUBEMAP_AUTO_DETECT = 0 # Automatically detect layout type
    CUBEMAP_LINE_VERTICAL # Layout is defined by a vertical line with faces
    CUBEMAP_LINE_HORIZONTAL # Layout is defined by an horizontal line with faces
    CUBEMAP_CROSS_THREE_BY_FOUR # Layout is defined by a 3x4 cross with cubemap faces
    CUBEMAP_CROSS_FOUR_BY_THREE # Layout is defined by a 4x3 cross with cubemap faces
    CUBEMAP_PANORAMA # Layout is defined by a panorama image (equirectangular map)
converter CubemapLayoutType2int32* (self: CubemapLayoutType): int32 = self.int32 
# Texture parameters: wrap mode
type TextureWrapMode* = enum 
    WRAP_REPEAT = 0 # Repeats texture in tiled mode
    WRAP_CLAMP # Clamps texture to edge pixel in tiled mode
    WRAP_MIRROR_REPEAT # Mirrors and repeats the texture in tiled mode
    WRAP_MIRROR_CLAMP # Mirrors and clamps to border the texture in tiled mode
converter TextureWrapMode2int32* (self: TextureWrapMode): int32 = self.int32 
# Font type, defines generation method
type FontType* = enum 
    FONT_DEFAULT = 0 # Default font generation, anti-aliased
    FONT_BITMAP # Bitmap font generation, no anti-aliasing
    FONT_SDF # SDF font generation, requires external shader
converter FontType2int32* (self: FontType): int32 = self.int32 
# Color blending modes (pre-defined)
type BlendMode* = enum 
    BLEND_ALPHA = 0 # Blend textures considering alpha (default)
    BLEND_ADDITIVE # Blend textures adding colors
    BLEND_MULTIPLIED # Blend textures multiplying colors
converter BlendMode2int32* (self: BlendMode): int32 = self.int32 
# Gestures type
# NOTE: It could be used as flags to enable only some gestures
type GestureType* = enum 
    GESTURE_NONE        = 0 
    GESTURE_TAP         = 1 
    GESTURE_DOUBLETAP   = 2 
    GESTURE_HOLD        = 4 
    GESTURE_DRAG        = 8 
    GESTURE_SWIPE_RIGHT = 16 
    GESTURE_SWIPE_LEFT  = 32 
    GESTURE_SWIPE_UP    = 64 
    GESTURE_SWIPE_DOWN  = 128 
    GESTURE_PINCH_IN    = 256 
    GESTURE_PINCH_OUT   = 512 
converter GestureType2int32* (self: GestureType): int32 = self.int32 
# Camera system modes
type CameraMode* = enum 
    CAMERA_CUSTOM = 0 
    CAMERA_FREE 
    CAMERA_ORBITAL 
    CAMERA_FIRST_PERSON 
    CAMERA_THIRD_PERSON 
converter CameraMode2int32* (self: CameraMode): int32 = self.int32 
# Camera projection modes
type CameraType* = enum 
    CAMERA_PERSPECTIVE = 0 
    CAMERA_ORTHOGRAPHIC 
converter CameraType2int32* (self: CameraType): int32 = self.int32 
# Type of n-patch
type NPatchType* = enum 
    NPT_9PATCH = 0 # Npatch defined by 3x3 tiles
    NPT_3PATCH_VERTICAL # Npatch defined by 1x3 tiles
    NPT_3PATCH_HORIZONTAL # Npatch defined by 3x1 tiles
converter NPatchType2int32* (self: NPatchType): int32 = self.int32 
# Callbacks to be implemented by users
# ------------------------------------------------------------------------------------
# Global Variables Definition
# ------------------------------------------------------------------------------------
# It's lonely here...
# ------------------------------------------------------------------------------------
# Window and Graphics Device Functions (Module: core)
# ------------------------------------------------------------------------------------
# Window-related functions
proc InitWindow*(width: int32; height: int32; title: cstring) {.RLAPI, importc: "InitWindow".} # Initialize window and OpenGL context
proc WindowShouldClose*(): bool {.RLAPI, importc: "WindowShouldClose".} # Check if KEY_ESCAPE pressed or Close icon pressed
proc CloseWindow*() {.RLAPI, importc: "CloseWindow".} # Close window and unload OpenGL context
proc IsWindowReady*(): bool {.RLAPI, importc: "IsWindowReady".} # Check if window has been initialized successfully
proc IsWindowMinimized*(): bool {.RLAPI, importc: "IsWindowMinimized".} # Check if window has been minimized (or lost focus)
proc IsWindowResized*(): bool {.RLAPI, importc: "IsWindowResized".} # Check if window has been resized
proc IsWindowHidden*(): bool {.RLAPI, importc: "IsWindowHidden".} # Check if window is currently hidden
proc ToggleFullscreen*() {.RLAPI, importc: "ToggleFullscreen".} # Toggle fullscreen mode (only PLATFORM_DESKTOP)
proc UnhideWindow*() {.RLAPI, importc: "UnhideWindow".} # Show the window
proc HideWindow*() {.RLAPI, importc: "HideWindow".} # Hide the window
proc SetWindowIcon*(image: Image) {.RLAPI, importc: "SetWindowIcon".} # Set icon for window (only PLATFORM_DESKTOP)
proc SetWindowTitle*(title: cstring) {.RLAPI, importc: "SetWindowTitle".} # Set title for window (only PLATFORM_DESKTOP)
proc SetWindowPosition*(x: int32; y: int32) {.RLAPI, importc: "SetWindowPosition".} # Set window position on screen (only PLATFORM_DESKTOP)
proc SetWindowMonitor*(monitor: int32) {.RLAPI, importc: "SetWindowMonitor".} # Set monitor for the current window (fullscreen mode)
proc SetWindowMinSize*(width: int32; height: int32) {.RLAPI, importc: "SetWindowMinSize".} # Set window minimum dimensions (for FLAG_WINDOW_RESIZABLE)
proc SetWindowSize*(width: int32; height: int32) {.RLAPI, importc: "SetWindowSize".} # Set window dimensions
proc GetWindowHandle*(): pointer {.RLAPI, importc: "GetWindowHandle".} # Get native window handle
proc GetScreenWidth*(): int32 {.RLAPI, importc: "GetScreenWidth".} # Get current screen width
proc GetScreenHeight*(): int32 {.RLAPI, importc: "GetScreenHeight".} # Get current screen height
proc GetMonitorCount*(): int32 {.RLAPI, importc: "GetMonitorCount".} # Get number of connected monitors
proc GetMonitorWidth*(monitor: int32): int32 {.RLAPI, importc: "GetMonitorWidth".} # Get primary monitor width
proc GetMonitorHeight*(monitor: int32): int32 {.RLAPI, importc: "GetMonitorHeight".} # Get primary monitor height
proc GetMonitorPhysicalWidth*(monitor: int32): int32 {.RLAPI, importc: "GetMonitorPhysicalWidth".} # Get primary monitor physical width in millimetres
proc GetMonitorPhysicalHeight*(monitor: int32): int32 {.RLAPI, importc: "GetMonitorPhysicalHeight".} # Get primary monitor physical height in millimetres
proc GetWindowPosition*(): Vector2 {.RLAPI, importc: "GetWindowPosition".} # Get window position XY on monitor
proc GetMonitorName*(monitor: int32): cstring {.RLAPI, importc: "GetMonitorName".} # Get the human-readable, UTF-8 encoded name of the primary monitor
proc GetClipboardText*(): cstring {.RLAPI, importc: "GetClipboardText".} # Get clipboard text content
proc SetClipboardText*(text: cstring) {.RLAPI, importc: "SetClipboardText".} # Set clipboard text content
# Cursor-related functions
proc ShowCursor*() {.RLAPI, importc: "ShowCursor".} # Shows cursor
proc HideCursor*() {.RLAPI, importc: "HideCursor".} # Hides cursor
proc IsCursorHidden*(): bool {.RLAPI, importc: "IsCursorHidden".} # Check if cursor is not visible
proc EnableCursor*() {.RLAPI, importc: "EnableCursor".} # Enables cursor (unlock cursor)
proc DisableCursor*() {.RLAPI, importc: "DisableCursor".} # Disables cursor (lock cursor)
# Drawing-related functions
proc ClearBackground*(color: Color) {.RLAPI, importc: "ClearBackground".} # Set background color (framebuffer clear color)
proc BeginDrawing*() {.RLAPI, importc: "BeginDrawing".} # Setup canvas (framebuffer) to start drawing
proc EndDrawing*() {.RLAPI, importc: "EndDrawing".} # End canvas drawing and swap buffers (double buffering)
proc BeginMode2D*(camera: Camera2D) {.RLAPI, importc: "BeginMode2D".} # Initialize 2D mode with custom camera (2D)
proc EndMode2D*() {.RLAPI, importc: "EndMode2D".} # Ends 2D mode with custom camera
proc BeginMode3D*(camera: Camera3D) {.RLAPI, importc: "BeginMode3D".} # Initializes 3D mode with custom camera (3D)
proc EndMode3D*() {.RLAPI, importc: "EndMode3D".} # Ends 3D mode and returns to default 2D orthographic mode
proc BeginTextureMode*(target: RenderTexture2D) {.RLAPI, importc: "BeginTextureMode".} # Initializes render texture for drawing
proc EndTextureMode*() {.RLAPI, importc: "EndTextureMode".} # Ends drawing to render texture
proc BeginScissorMode*(x: int32; y: int32; width: int32; height: int32) {.RLAPI, importc: "BeginScissorMode".} # Begin scissor mode (define screen area for following drawing)
proc EndScissorMode*() {.RLAPI, importc: "EndScissorMode".} # End scissor mode
# Screen-space-related functions
proc GetMouseRay*(mousePosition: Vector2; camera: Camera): Ray {.RLAPI, importc: "GetMouseRay".} # Returns a ray trace from mouse position
proc GetCameraMatrix*(camera: Camera): Matrix {.RLAPI, importc: "GetCameraMatrix".} # Returns camera transform matrix (view matrix)
proc GetCameraMatrix2D*(camera: Camera2D): Matrix {.RLAPI, importc: "GetCameraMatrix2D".} # Returns camera 2d transform matrix
proc GetWorldToScreen*(position: Vector3; camera: Camera): Vector2 {.RLAPI, importc: "GetWorldToScreen".} # Returns the screen space position for a 3d world space position
proc GetWorldToScreenEx*(position: Vector3; camera: Camera; width: int32; height: int32): Vector2 {.RLAPI, importc: "GetWorldToScreenEx".} # Returns size position for a 3d world space position
proc GetWorldToScreen2D*(position: Vector2; camera: Camera2D): Vector2 {.RLAPI, importc: "GetWorldToScreen2D".} # Returns the screen space position for a 2d camera world space position
proc GetScreenToWorld2D*(position: Vector2; camera: Camera2D): Vector2 {.RLAPI, importc: "GetScreenToWorld2D".} # Returns the world space position for a 2d camera screen space position
# Timing-related functions
proc SetTargetFPS*(fps: int32) {.RLAPI, importc: "SetTargetFPS".} # Set target FPS (maximum)
proc GetFPS*(): int32 {.RLAPI, importc: "GetFPS".} # Returns current FPS
proc GetFrameTime*(): float32 {.RLAPI, importc: "GetFrameTime".} # Returns time in seconds for last frame drawn
proc GetTime*(): float64 {.RLAPI, importc: "GetTime".} # Returns elapsed time in seconds since InitWindow()
# Color-related functions
proc ColorToInt*(color: Color): int32 {.RLAPI, importc: "ColorToInt".} # Returns hexadecimal value for a Color
proc ColorNormalize*(color: Color): Vector4 {.RLAPI, importc: "ColorNormalize".} # Returns color normalized as float [0..1]
proc ColorFromNormalized*(normalized: Vector4): Color {.RLAPI, importc: "ColorFromNormalized".} # Returns color from normalized values [0..1]
proc ColorToHSV*(color: Color): Vector3 {.RLAPI, importc: "ColorToHSV".} # Returns HSV values for a Color
proc ColorFromHSV*(hsv: Vector3): Color {.RLAPI, importc: "ColorFromHSV".} # Returns a Color from HSV values
proc GetColor*(hexValue: int32): Color {.RLAPI, importc: "GetColor".} # Returns a Color struct from hexadecimal value
proc Fade*(color: Color; alpha: float32): Color {.RLAPI, importc: "Fade".} # Color fade-in or fade-out, alpha goes from 0.0f to 1.0f
# Misc. functions
proc SetConfigFlags*(flags: uint32) {.RLAPI, importc: "SetConfigFlags".} # Setup window configuration flags (view FLAGS)
proc SetTraceLogLevel*(logType: int32) {.RLAPI, importc: "SetTraceLogLevel".} # Set the current threshold (minimum) log level
proc SetTraceLogExit*(logType: int32) {.RLAPI, importc: "SetTraceLogExit".} # Set the exit threshold (minimum) log level
proc SetTraceLogCallback*(callback: int) {.RLAPI, importc: "SetTraceLogCallback".} # Set a trace log callback to enable custom logging
proc TraceLog*(logType: int32; text: cstring) {.RLAPI, varargs, importc: "TraceLog".} # Show trace log messages (LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERROR)
proc TakeScreenshot*(fileName: cstring) {.RLAPI, importc: "TakeScreenshot".} # Takes a screenshot of current screen (saved a .png)
proc GetRandomValue*(min: int32; max: int32): int32 {.RLAPI, importc: "GetRandomValue".} # Returns a random value between min and max (both included)
# Files management functions
proc FileExists*(fileName: cstring): bool {.RLAPI, importc: "FileExists".} # Check if file exists
proc IsFileExtension*(fileName: cstring; ext: cstring): bool {.RLAPI, importc: "IsFileExtension".} # Check file extension
proc DirectoryExists*(dirPath: cstring): bool {.RLAPI, importc: "DirectoryExists".} # Check if a directory path exists
proc GetExtension*(fileName: cstring): cstring {.RLAPI, importc: "GetExtension".} # Get pointer to extension for a filename string
proc GetFileName*(filePath: cstring): cstring {.RLAPI, importc: "GetFileName".} # Get pointer to filename for a path string
proc GetFileNameWithoutExt*(filePath: cstring): cstring {.RLAPI, importc: "GetFileNameWithoutExt".} # Get filename string without extension (uses static string)
proc GetDirectoryPath*(filePath: cstring): cstring {.RLAPI, importc: "GetDirectoryPath".} # Get full path for a given fileName with path (uses static string)
proc GetPrevDirectoryPath*(dirPath: cstring): cstring {.RLAPI, importc: "GetPrevDirectoryPath".} # Get previous directory path for a given path (uses static string)
proc GetWorkingDirectory*(): cstring {.RLAPI, importc: "GetWorkingDirectory".} # Get current working directory (uses static string)
proc GetDirectoryFiles*(dirPath: cstring; count: pointer): ptr char {.RLAPI, importc: "GetDirectoryFiles".} # Get filenames in a directory path (memory should be freed)
proc ClearDirectoryFiles*() {.RLAPI, importc: "ClearDirectoryFiles".} # Clear directory files paths buffers (free memory)
proc ChangeDirectory*(dir: cstring): bool {.RLAPI, importc: "ChangeDirectory".} # Change working directory, returns true if success
proc IsFileDropped*(): bool {.RLAPI, importc: "IsFileDropped".} # Check if a file has been dropped into window
proc GetDroppedFiles*(count: pointer): ptr char {.RLAPI, importc: "GetDroppedFiles".} # Get dropped files names (memory should be freed)
proc ClearDroppedFiles*() {.RLAPI, importc: "ClearDroppedFiles".} # Clear dropped files paths buffer (free memory)
proc GetFileModTime*(fileName: cstring): int32 {.RLAPI, importc: "GetFileModTime".} # Get file modification time (last write time)
proc CompressData*(data: uint8; dataLength: int32; compDataLength: pointer): uint8 {.RLAPI, importc: "CompressData".} # Compress data (DEFLATE algorythm)
proc DecompressData*(compData: uint8; compDataLength: int32; dataLength: pointer): uint8 {.RLAPI, importc: "DecompressData".} # Decompress data (DEFLATE algorythm)
# Persistent storage management
proc StorageSaveValue*(position: int32; value: int32) {.RLAPI, importc: "StorageSaveValue".} # Save integer value to storage file (to defined position)
proc StorageLoadValue*(position: int32): int32 {.RLAPI, importc: "StorageLoadValue".} # Load integer value from storage file (from defined position)
proc OpenURL*(url: cstring) {.RLAPI, importc: "OpenURL".} # Open URL with default system browser (if available)
# ------------------------------------------------------------------------------------
# Input Handling Functions (Module: core)
# ------------------------------------------------------------------------------------
# Input-related functions: keyboard
proc IsKeyPressed*(key: int32): bool {.RLAPI, importc: "IsKeyPressed".} # Detect if a key has been pressed once
proc IsKeyDown*(key: int32): bool {.RLAPI, importc: "IsKeyDown".} # Detect if a key is being pressed
proc IsKeyReleased*(key: int32): bool {.RLAPI, importc: "IsKeyReleased".} # Detect if a key has been released once
proc IsKeyUp*(key: int32): bool {.RLAPI, importc: "IsKeyUp".} # Detect if a key is NOT being pressed
proc SetExitKey*(key: int32) {.RLAPI, importc: "SetExitKey".} # Set a custom key to exit program (default is ESC)
proc GetKeyPressed*(): int32 {.RLAPI, importc: "GetKeyPressed".} # Get key pressed, call it multiple times for chars queued
# Input-related functions: gamepads
proc IsGamepadAvailable*(gamepad: int32): bool {.RLAPI, importc: "IsGamepadAvailable".} # Detect if a gamepad is available
proc IsGamepadName*(gamepad: int32; name: cstring): bool {.RLAPI, importc: "IsGamepadName".} # Check gamepad name (if available)
proc GetGamepadName*(gamepad: int32): cstring {.RLAPI, importc: "GetGamepadName".} # Return gamepad internal name id
proc IsGamepadButtonPressed*(gamepad: int32; button: int32): bool {.RLAPI, importc: "IsGamepadButtonPressed".} # Detect if a gamepad button has been pressed once
proc IsGamepadButtonDown*(gamepad: int32; button: int32): bool {.RLAPI, importc: "IsGamepadButtonDown".} # Detect if a gamepad button is being pressed
proc IsGamepadButtonReleased*(gamepad: int32; button: int32): bool {.RLAPI, importc: "IsGamepadButtonReleased".} # Detect if a gamepad button has been released once
proc IsGamepadButtonUp*(gamepad: int32; button: int32): bool {.RLAPI, importc: "IsGamepadButtonUp".} # Detect if a gamepad button is NOT being pressed
proc GetGamepadButtonPressed*(): int32 {.RLAPI, importc: "GetGamepadButtonPressed".} # Get the last gamepad button pressed
proc GetGamepadAxisCount*(gamepad: int32): int32 {.RLAPI, importc: "GetGamepadAxisCount".} # Return gamepad axis count for a gamepad
proc GetGamepadAxisMovement*(gamepad: int32; axis: int32): float32 {.RLAPI, importc: "GetGamepadAxisMovement".} # Return axis movement value for a gamepad axis
# Input-related functions: mouse
proc IsMouseButtonPressed*(button: int32): bool {.RLAPI, importc: "IsMouseButtonPressed".} # Detect if a mouse button has been pressed once
proc IsMouseButtonDown*(button: int32): bool {.RLAPI, importc: "IsMouseButtonDown".} # Detect if a mouse button is being pressed
proc IsMouseButtonReleased*(button: int32): bool {.RLAPI, importc: "IsMouseButtonReleased".} # Detect if a mouse button has been released once
proc IsMouseButtonUp*(button: int32): bool {.RLAPI, importc: "IsMouseButtonUp".} # Detect if a mouse button is NOT being pressed
proc GetMouseX*(): int32 {.RLAPI, importc: "GetMouseX".} # Returns mouse position X
proc GetMouseY*(): int32 {.RLAPI, importc: "GetMouseY".} # Returns mouse position Y
proc GetMousePosition*(): Vector2 {.RLAPI, importc: "GetMousePosition".} # Returns mouse position XY
proc SetMousePosition*(x: int32; y: int32) {.RLAPI, importc: "SetMousePosition".} # Set mouse position XY
proc SetMouseOffset*(offsetX: int32; offsetY: int32) {.RLAPI, importc: "SetMouseOffset".} # Set mouse offset
proc SetMouseScale*(scaleX: float32; scaleY: float32) {.RLAPI, importc: "SetMouseScale".} # Set mouse scaling
proc GetMouseWheelMove*(): int32 {.RLAPI, importc: "GetMouseWheelMove".} # Returns mouse wheel movement Y
# Input-related functions: touch
proc GetTouchX*(): int32 {.RLAPI, importc: "GetTouchX".} # Returns touch position X for touch point 0 (relative to screen size)
proc GetTouchY*(): int32 {.RLAPI, importc: "GetTouchY".} # Returns touch position Y for touch point 0 (relative to screen size)
proc GetTouchPosition*(index: int32): Vector2 {.RLAPI, importc: "GetTouchPosition".} # Returns touch position XY for a touch point index (relative to screen size)
# ------------------------------------------------------------------------------------
# Gestures and Touch Handling Functions (Module: gestures)
# ------------------------------------------------------------------------------------
proc SetGesturesEnabled*(gestureFlags: uint32) {.RLAPI, importc: "SetGesturesEnabled".} # Enable a set of gestures using flags
proc IsGestureDetected*(gesture: int32): bool {.RLAPI, importc: "IsGestureDetected".} # Check if a gesture have been detected
proc GetGestureDetected*(): int32 {.RLAPI, importc: "GetGestureDetected".} # Get latest detected gesture
proc GetTouchPointsCount*(): int32 {.RLAPI, importc: "GetTouchPointsCount".} # Get touch points count
proc GetGestureHoldDuration*(): float32 {.RLAPI, importc: "GetGestureHoldDuration".} # Get gesture hold time in milliseconds
proc GetGestureDragVector*(): Vector2 {.RLAPI, importc: "GetGestureDragVector".} # Get gesture drag vector
proc GetGestureDragAngle*(): float32 {.RLAPI, importc: "GetGestureDragAngle".} # Get gesture drag angle
proc GetGesturePinchVector*(): Vector2 {.RLAPI, importc: "GetGesturePinchVector".} # Get gesture pinch delta
proc GetGesturePinchAngle*(): float32 {.RLAPI, importc: "GetGesturePinchAngle".} # Get gesture pinch angle
# ------------------------------------------------------------------------------------
# Camera System Functions (Module: camera)
# ------------------------------------------------------------------------------------
proc SetCameraMode*(camera: Camera; mode: int32) {.RLAPI, importc: "SetCameraMode".} # Set camera mode (multiple camera modes available)
proc UpdateCamera*(camera: ptr Camera) {.RLAPI, importc: "UpdateCamera".} # Update camera position for selected mode
proc SetCameraPanControl*(panKey: int32) {.RLAPI, importc: "SetCameraPanControl".} # Set camera pan key to combine with mouse movement (free camera)
proc SetCameraAltControl*(altKey: int32) {.RLAPI, importc: "SetCameraAltControl".} # Set camera alt key to combine with mouse movement (free camera)
proc SetCameraSmoothZoomControl*(szKey: int32) {.RLAPI, importc: "SetCameraSmoothZoomControl".} # Set camera smooth zoom key to combine with mouse (free camera)
proc SetCameraMoveControls*(frontKey: int32; backKey: int32; rightKey: int32; leftKey: int32; upKey: int32; downKey: int32) {.RLAPI, importc: "SetCameraMoveControls".} # Set camera move controls (1st person and 3rd person cameras)
# ------------------------------------------------------------------------------------
# Basic Shapes Drawing Functions (Module: shapes)
# ------------------------------------------------------------------------------------
# Basic shapes drawing functions
proc DrawPixel*(posX: int32; posY: int32; color: Color) {.RLAPI, importc: "DrawPixel".} # Draw a pixel
proc DrawPixelV*(position: Vector2; color: Color) {.RLAPI, importc: "DrawPixelV".} # Draw a pixel (Vector version)
proc DrawLine*(startPosX: int32; startPosY: int32; endPosX: int32; endPosY: int32; color: Color) {.RLAPI, importc: "DrawLine".} # Draw a line
proc DrawLineV*(startPos: Vector2; endPos: Vector2; color: Color) {.RLAPI, importc: "DrawLineV".} # Draw a line (Vector version)
proc DrawLineEx*(startPos: Vector2; endPos: Vector2; thick: float32; color: Color) {.RLAPI, importc: "DrawLineEx".} # Draw a line defining thickness
proc DrawLineBezier*(startPos: Vector2; endPos: Vector2; thick: float32; color: Color) {.RLAPI, importc: "DrawLineBezier".} # Draw a line using cubic-bezier curves in-out
proc DrawLineStrip*(points: ptr Vector2; numPoints: int32; color: Color) {.RLAPI, importc: "DrawLineStrip".} # Draw lines sequence
proc DrawCircle*(centerX: int32; centerY: int32; radius: float32; color: Color) {.RLAPI, importc: "DrawCircle".} # Draw a color-filled circle
proc DrawCircleSector*(center: Vector2; radius: float32; startAngle: int32; endAngle: int32; segments: int32; color: Color) {.RLAPI, importc: "DrawCircleSector".} # Draw a piece of a circle
proc DrawCircleSectorLines*(center: Vector2; radius: float32; startAngle: int32; endAngle: int32; segments: int32; color: Color) {.RLAPI, importc: "DrawCircleSectorLines".} # Draw circle sector outline
proc DrawCircleGradient*(centerX: int32; centerY: int32; radius: float32; color1: Color; color2: Color) {.RLAPI, importc: "DrawCircleGradient".} # Draw a gradient-filled circle
proc DrawCircleV*(center: Vector2; radius: float32; color: Color) {.RLAPI, importc: "DrawCircleV".} # Draw a color-filled circle (Vector version)
proc DrawCircleLines*(centerX: int32; centerY: int32; radius: float32; color: Color) {.RLAPI, importc: "DrawCircleLines".} # Draw circle outline
proc DrawEllipse*(centerX: int32; centerY: int32; radiusH: float32; radiusV: float32; color: Color) {.RLAPI, importc: "DrawEllipse".} # Draw ellipse
proc DrawEllipseLines*(centerX: int32; centerY: int32; radiusH: float32; radiusV: float32; color: Color) {.RLAPI, importc: "DrawEllipseLines".} # Draw ellipse outline
proc DrawRing*(center: Vector2; innerRadius: float32; outerRadius: float32; startAngle: int32; endAngle: int32; segments: int32; color: Color) {.RLAPI, importc: "DrawRing".} # Draw ring
proc DrawRingLines*(center: Vector2; innerRadius: float32; outerRadius: float32; startAngle: int32; endAngle: int32; segments: int32; color: Color) {.RLAPI, importc: "DrawRingLines".} # Draw ring outline
proc DrawRectangle*(posX: int32; posY: int32; width: int32; height: int32; color: Color) {.RLAPI, importc: "DrawRectangle".} # Draw a color-filled rectangle
proc DrawRectangleV*(position: Vector2; size: Vector2; color: Color) {.RLAPI, importc: "DrawRectangleV".} # Draw a color-filled rectangle (Vector version)
proc DrawRectangleRec*(rec: Rectangle; color: Color) {.RLAPI, importc: "DrawRectangleRec".} # Draw a color-filled rectangle
proc DrawRectanglePro*(rec: Rectangle; origin: Vector2; rotation: float32; color: Color) {.RLAPI, importc: "DrawRectanglePro".} # Draw a color-filled rectangle with pro parameters
proc DrawRectangleGradientV*(posX: int32; posY: int32; width: int32; height: int32; color1: Color; color2: Color) {.RLAPI, importc: "DrawRectangleGradientV".} # Draw a vertical-gradient-filled rectangle
proc DrawRectangleGradientH*(posX: int32; posY: int32; width: int32; height: int32; color1: Color; color2: Color) {.RLAPI, importc: "DrawRectangleGradientH".} # Draw a horizontal-gradient-filled rectangle
proc DrawRectangleGradientEx*(rec: Rectangle; col1: Color; col2: Color; col3: Color; col4: Color) {.RLAPI, importc: "DrawRectangleGradientEx".} # Draw a gradient-filled rectangle with custom vertex colors
proc DrawRectangleLines*(posX: int32; posY: int32; width: int32; height: int32; color: Color) {.RLAPI, importc: "DrawRectangleLines".} # Draw rectangle outline
proc DrawRectangleLinesEx*(rec: Rectangle; lineThick: int32; color: Color) {.RLAPI, importc: "DrawRectangleLinesEx".} # Draw rectangle outline with extended parameters
proc DrawRectangleRounded*(rec: Rectangle; roundness: float32; segments: int32; color: Color) {.RLAPI, importc: "DrawRectangleRounded".} # Draw rectangle with rounded edges
proc DrawRectangleRoundedLines*(rec: Rectangle; roundness: float32; segments: int32; lineThick: int32; color: Color) {.RLAPI, importc: "DrawRectangleRoundedLines".} # Draw rectangle with rounded edges outline
proc DrawTriangle*(v1: Vector2; v2: Vector2; v3: Vector2; color: Color) {.RLAPI, importc: "DrawTriangle".} # Draw a color-filled triangle (vertex in counter-clockwise order!)
proc DrawTriangleLines*(v1: Vector2; v2: Vector2; v3: Vector2; color: Color) {.RLAPI, importc: "DrawTriangleLines".} # Draw triangle outline (vertex in counter-clockwise order!)
proc DrawTriangleFan*(points: ptr Vector2; numPoints: int32; color: Color) {.RLAPI, importc: "DrawTriangleFan".} # Draw a triangle fan defined by points (first vertex is the center)
proc DrawTriangleStrip*(points: ptr Vector2; pointsCount: int32; color: Color) {.RLAPI, importc: "DrawTriangleStrip".} # Draw a triangle strip defined by points
proc DrawPoly*(center: Vector2; sides: int32; radius: float32; rotation: float32; color: Color) {.RLAPI, importc: "DrawPoly".} # Draw a regular polygon (Vector version)
proc DrawPolyLines*(center: Vector2; sides: int32; radius: float32; rotation: float32; color: Color) {.RLAPI, importc: "DrawPolyLines".} # Draw a polygon outline of n sides
# Basic shapes collision detection functions
proc CheckCollisionRecs*(rec1: Rectangle; rec2: Rectangle): bool {.RLAPI, importc: "CheckCollisionRecs".} # Check collision between two rectangles
proc CheckCollisionCircles*(center1: Vector2; radius1: float32; center2: Vector2; radius2: float32): bool {.RLAPI, importc: "CheckCollisionCircles".} # Check collision between two circles
proc CheckCollisionCircleRec*(center: Vector2; radius: float32; rec: Rectangle): bool {.RLAPI, importc: "CheckCollisionCircleRec".} # Check collision between circle and rectangle
proc GetCollisionRec*(rec1: Rectangle; rec2: Rectangle): Rectangle {.RLAPI, importc: "GetCollisionRec".} # Get collision rectangle for two rectangles collision
proc CheckCollisionPointRec*(point: Vector2; rec: Rectangle): bool {.RLAPI, importc: "CheckCollisionPointRec".} # Check if point is inside rectangle
proc CheckCollisionPointCircle*(point: Vector2; center: Vector2; radius: float32): bool {.RLAPI, importc: "CheckCollisionPointCircle".} # Check if point is inside circle
proc CheckCollisionPointTriangle*(point: Vector2; p1: Vector2; p2: Vector2; p3: Vector2): bool {.RLAPI, importc: "CheckCollisionPointTriangle".} # Check if point is inside a triangle
# ------------------------------------------------------------------------------------
# Texture Loading and Drawing Functions (Module: textures)
# ------------------------------------------------------------------------------------
# Image/Texture2D data loading/unloading/saving functions
proc LoadImage*(fileName: cstring): Image {.RLAPI, importc: "LoadImage".} # Load image from file into CPU memory (RAM)
proc LoadImageEx*(pixels: ptr Color; width: int32; height: int32): Image {.RLAPI, importc: "LoadImageEx".} # Load image from Color array data (RGBA - 32bit)
proc LoadImagePro*(data: pointer; width: int32; height: int32; format: int32): Image {.RLAPI, importc: "LoadImagePro".} # Load image from raw data with parameters
proc LoadImageRaw*(fileName: cstring; width: int32; height: int32; format: int32; headerSize: int32): Image {.RLAPI, importc: "LoadImageRaw".} # Load image from RAW file data
proc ExportImage*(image: Image; fileName: cstring) {.RLAPI, importc: "ExportImage".} # Export image data to file
proc ExportImageAsCode*(image: Image; fileName: cstring) {.RLAPI, importc: "ExportImageAsCode".} # Export image as code file defining an array of bytes
proc LoadTexture*(fileName: cstring): Texture2D {.RLAPI, importc: "LoadTexture".} # Load texture from file into GPU memory (VRAM)
proc LoadTextureFromImage*(image: Image): Texture2D {.RLAPI, importc: "LoadTextureFromImage".} # Load texture from image data
proc LoadTextureCubemap*(image: Image; layoutType: int32): TextureCubemap {.RLAPI, importc: "LoadTextureCubemap".} # Load cubemap from image, multiple image cubemap layouts supported
proc LoadRenderTexture*(width: int32; height: int32): RenderTexture2D {.RLAPI, importc: "LoadRenderTexture".} # Load texture for rendering (framebuffer)
proc UnloadImage*(image: Image) {.RLAPI, importc: "UnloadImage".} # Unload image from CPU memory (RAM)
proc UnloadTexture*(texture: Texture2D) {.RLAPI, importc: "UnloadTexture".} # Unload texture from GPU memory (VRAM)
proc UnloadRenderTexture*(target: RenderTexture2D) {.RLAPI, importc: "UnloadRenderTexture".} # Unload render texture from GPU memory (VRAM)
proc GetImageData*(image: Image): ptr Color {.RLAPI, importc: "GetImageData".} # Get pixel data from image as a Color struct array
proc GetImageDataNormalized*(image: Image): ptr Vector4 {.RLAPI, importc: "GetImageDataNormalized".} # Get pixel data from image as Vector4 array (float normalized)
proc GetImageAlphaBorder*(image: Image; threshold: float32): Rectangle {.RLAPI, importc: "GetImageAlphaBorder".} # Get image alpha border rectangle
proc GetPixelDataSize*(width: int32; height: int32; format: int32): int32 {.RLAPI, importc: "GetPixelDataSize".} # Get pixel data size in bytes (image or texture)
proc GetTextureData*(texture: Texture2D): Image {.RLAPI, importc: "GetTextureData".} # Get pixel data from GPU texture and return an Image
proc GetScreenData*(): Image {.RLAPI, importc: "GetScreenData".} # Get pixel data from screen buffer and return an Image (screenshot)
proc UpdateTexture*(texture: Texture2D; pixels: pointer) {.RLAPI, importc: "UpdateTexture".} # Update GPU texture with new data
# Image manipulation functions
proc ImageCopy*(image: Image): Image {.RLAPI, importc: "ImageCopy".} # Create an image duplicate (useful for transformations)
proc ImageFromImage*(image: Image; rec: Rectangle): Image {.RLAPI, importc: "ImageFromImage".} # Create an image from another image piece
proc ImageToPOT*(image: ptr Image; fillColor: Color) {.RLAPI, importc: "ImageToPOT".} # Convert image to POT (power-of-two)
proc ImageFormat*(image: ptr Image; newFormat: int32) {.RLAPI, importc: "ImageFormat".} # Convert image data to desired format
proc ImageAlphaMask*(image: ptr Image; alphaMask: Image) {.RLAPI, importc: "ImageAlphaMask".} # Apply alpha mask to image
proc ImageAlphaClear*(image: ptr Image; color: Color; threshold: float32) {.RLAPI, importc: "ImageAlphaClear".} # Clear alpha channel to desired color
proc ImageAlphaCrop*(image: ptr Image; threshold: float32) {.RLAPI, importc: "ImageAlphaCrop".} # Crop image depending on alpha value
proc ImageAlphaPremultiply*(image: ptr Image) {.RLAPI, importc: "ImageAlphaPremultiply".} # Premultiply alpha channel
proc ImageCrop*(image: ptr Image; crop: Rectangle) {.RLAPI, importc: "ImageCrop".} # Crop an image to a defined rectangle
proc ImageResize*(image: ptr Image; newWidth: int32; newHeight: int32) {.RLAPI, importc: "ImageResize".} # Resize image (Bicubic scaling algorithm)
proc ImageResizeNN*(image: ptr Image; newWidth: int32; newHeight: int32) {.RLAPI, importc: "ImageResizeNN".} # Resize image (Nearest-Neighbor scaling algorithm)
proc ImageResizeCanvas*(image: ptr Image; newWidth: int32; newHeight: int32; offsetX: int32; offsetY: int32; color: Color) {.RLAPI, importc: "ImageResizeCanvas".} # Resize canvas and fill with color
proc ImageMipmaps*(image: ptr Image) {.RLAPI, importc: "ImageMipmaps".} # Generate all mipmap levels for a provided image
proc ImageDither*(image: ptr Image; rBpp: int32; gBpp: int32; bBpp: int32; aBpp: int32) {.RLAPI, importc: "ImageDither".} # Dither image data to 16bpp or lower (Floyd-Steinberg dithering)
proc ImageExtractPalette*(image: Image; maxPaletteSize: int32; extractCount: pointer): ptr Color {.RLAPI, importc: "ImageExtractPalette".} # Extract color palette from image to maximum size (memory should be freed)
proc ImageText*(text: cstring; fontSize: int32; color: Color): Image {.RLAPI, importc: "ImageText".} # Create an image from text (default font)
proc ImageTextEx*(font: Font; text: cstring; fontSize: float32; spacing: float32; tint: Color): Image {.RLAPI, importc: "ImageTextEx".} # Create an image from text (custom sprite font)
proc ImageDraw*(dst: ptr Image; src: Image; srcRec: Rectangle; dstRec: Rectangle; tint: Color) {.RLAPI, importc: "ImageDraw".} # Draw a source image within a destination image (tint applied to source)
proc ImageDrawRectangle*(dst: ptr Image; rec: Rectangle; color: Color) {.RLAPI, importc: "ImageDrawRectangle".} # Draw rectangle within an image
proc ImageDrawRectangleLines*(dst: ptr Image; rec: Rectangle; thick: int32; color: Color) {.RLAPI, importc: "ImageDrawRectangleLines".} # Draw rectangle lines within an image
proc ImageDrawText*(dst: ptr Image; position: Vector2; text: cstring; fontSize: int32; color: Color) {.RLAPI, importc: "ImageDrawText".} # Draw text (default font) within an image (destination)
proc ImageDrawTextEx*(dst: ptr Image; position: Vector2; font: Font; text: cstring; fontSize: float32; spacing: float32; color: Color) {.RLAPI, importc: "ImageDrawTextEx".} # Draw text (custom sprite font) within an image (destination)
proc ImageFlipVertical*(image: ptr Image) {.RLAPI, importc: "ImageFlipVertical".} # Flip image vertically
proc ImageFlipHorizontal*(image: ptr Image) {.RLAPI, importc: "ImageFlipHorizontal".} # Flip image horizontally
proc ImageRotateCW*(image: ptr Image) {.RLAPI, importc: "ImageRotateCW".} # Rotate image clockwise 90deg
proc ImageRotateCCW*(image: ptr Image) {.RLAPI, importc: "ImageRotateCCW".} # Rotate image counter-clockwise 90deg
proc ImageColorTint*(image: ptr Image; color: Color) {.RLAPI, importc: "ImageColorTint".} # Modify image color: tint
proc ImageColorInvert*(image: ptr Image) {.RLAPI, importc: "ImageColorInvert".} # Modify image color: invert
proc ImageColorGrayscale*(image: ptr Image) {.RLAPI, importc: "ImageColorGrayscale".} # Modify image color: grayscale
proc ImageColorContrast*(image: ptr Image; contrast: float32) {.RLAPI, importc: "ImageColorContrast".} # Modify image color: contrast (-100 to 100)
proc ImageColorBrightness*(image: ptr Image; brightness: int32) {.RLAPI, importc: "ImageColorBrightness".} # Modify image color: brightness (-255 to 255)
proc ImageColorReplace*(image: ptr Image; color: Color; replace: Color) {.RLAPI, importc: "ImageColorReplace".} # Modify image color: replace color
# Image generation functions
proc GenImageColor*(width: int32; height: int32; color: Color): Image {.RLAPI, importc: "GenImageColor".} # Generate image: plain color
proc GenImageGradientV*(width: int32; height: int32; top: Color; bottom: Color): Image {.RLAPI, importc: "GenImageGradientV".} # Generate image: vertical gradient
proc GenImageGradientH*(width: int32; height: int32; left: Color; right: Color): Image {.RLAPI, importc: "GenImageGradientH".} # Generate image: horizontal gradient
proc GenImageGradientRadial*(width: int32; height: int32; density: float32; inner: Color; outer: Color): Image {.RLAPI, importc: "GenImageGradientRadial".} # Generate image: radial gradient
proc GenImageChecked*(width: int32; height: int32; checksX: int32; checksY: int32; col1: Color; col2: Color): Image {.RLAPI, importc: "GenImageChecked".} # Generate image: checked
proc GenImageWhiteNoise*(width: int32; height: int32; factor: float32): Image {.RLAPI, importc: "GenImageWhiteNoise".} # Generate image: white noise
proc GenImagePerlinNoise*(width: int32; height: int32; offsetX: int32; offsetY: int32; scale: float32): Image {.RLAPI, importc: "GenImagePerlinNoise".} # Generate image: perlin noise
proc GenImageCellular*(width: int32; height: int32; tileSize: int32): Image {.RLAPI, importc: "GenImageCellular".} # Generate image: cellular algorithm. Bigger tileSize means bigger cells
# Texture2D configuration functions
proc GenTextureMipmaps*(texture: ptr Texture2D) {.RLAPI, importc: "GenTextureMipmaps".} # Generate GPU mipmaps for a texture
proc SetTextureFilter*(texture: Texture2D; filterMode: int32) {.RLAPI, importc: "SetTextureFilter".} # Set texture scaling filter mode
proc SetTextureWrap*(texture: Texture2D; wrapMode: int32) {.RLAPI, importc: "SetTextureWrap".} # Set texture wrapping mode
# Texture2D drawing functions
proc DrawTexture*(texture: Texture2D; posX: int32; posY: int32; tint: Color) {.RLAPI, importc: "DrawTexture".} # Draw a Texture2D
proc DrawTextureV*(texture: Texture2D; position: Vector2; tint: Color) {.RLAPI, importc: "DrawTextureV".} # Draw a Texture2D with position defined as Vector2
proc DrawTextureEx*(texture: Texture2D; position: Vector2; rotation: float32; scale: float32; tint: Color) {.RLAPI, importc: "DrawTextureEx".} # Draw a Texture2D with extended parameters
proc DrawTextureRec*(texture: Texture2D; sourceRec: Rectangle; position: Vector2; tint: Color) {.RLAPI, importc: "DrawTextureRec".} # Draw a part of a texture defined by a rectangle
proc DrawTextureQuad*(texture: Texture2D; tiling: Vector2; offset: Vector2; quad: Rectangle; tint: Color) {.RLAPI, importc: "DrawTextureQuad".} # Draw texture quad with tiling and offset parameters
proc DrawTexturePro*(texture: Texture2D; sourceRec: Rectangle; destRec: Rectangle; origin: Vector2; rotation: float32; tint: Color) {.RLAPI, importc: "DrawTexturePro".} # Draw a part of a texture defined by a rectangle with 'pro' parameters
proc DrawTextureNPatch*(texture: Texture2D; nPatchInfo: NPatchInfo; destRec: Rectangle; origin: Vector2; rotation: float32; tint: Color) {.RLAPI, importc: "DrawTextureNPatch".} # Draws a texture (or part of it) that stretches or shrinks nicely
# ------------------------------------------------------------------------------------
# Font Loading and Text Drawing Functions (Module: text)
# ------------------------------------------------------------------------------------
# Font loading/unloading functions
proc GetFontDefault*(): Font {.RLAPI, importc: "GetFontDefault".} # Get the default Font
proc LoadFont*(fileName: cstring): Font {.RLAPI, importc: "LoadFont".} # Load font from file into GPU memory (VRAM)
proc LoadFontEx*(fileName: cstring; fontSize: int32; fontChars: pointer; charsCount: int32): Font {.RLAPI, importc: "LoadFontEx".} # Load font from file with extended parameters
proc LoadFontFromImage*(image: Image; key: Color; firstChar: int32): Font {.RLAPI, importc: "LoadFontFromImage".} # Load font from Image (XNA style)
proc LoadFontData*(fileName: cstring; fontSize: int32; fontChars: pointer; charsCount: int32; typex: int32): ptr CharInfo {.RLAPI, importc: "LoadFontData".} # Load font data for further use
proc GenImageFontAtlas*(chars: ptr ptr CharInfo; recs: ptr Rectangle; charsCount: int32; fontSize: int32; padding: int32; packMethod: int32): Image {.RLAPI, importc: "GenImageFontAtlas".} # Generate image font atlas using chars info
proc UnloadFont*(font: Font) {.RLAPI, importc: "UnloadFont".} # Unload Font from GPU memory (VRAM)
# Text drawing functions
proc DrawFPS*(posX: int32; posY: int32) {.RLAPI, importc: "DrawFPS".} # Shows current FPS
proc DrawText*(text: cstring; posX: int32; posY: int32; fontSize: int32; color: Color) {.RLAPI, importc: "DrawText".} # Draw text (using default font)
proc DrawTextEx*(font: Font; text: cstring; position: Vector2; fontSize: float32; spacing: float32; tint: Color) {.RLAPI, importc: "DrawTextEx".} # Draw text using font and additional parameters
proc DrawTextRec*(font: Font; text: cstring; rec: Rectangle; fontSize: float32; spacing: float32; wordWrap: bool; tint: Color) {.RLAPI, importc: "DrawTextRec".} # Draw text using font inside rectangle limits
proc DrawTextRecEx*(font: Font; text: cstring; rec: Rectangle; fontSize: float32; spacing: float32; wordWrap: bool; tint: Color; selectStart: int32; selectLength: int32; selectTint: Color; selectBackTint: Color) {.RLAPI, importc: "DrawTextRecEx".} # Draw text using font inside rectangle limits with support for text selection
proc DrawTextCodepoint*(font: Font; codepoint: int32; position: Vector2; scale: float32; tint: Color) {.RLAPI, importc: "DrawTextCodepoint".} # Draw one character (codepoint)
# Text misc. functions
proc MeasureText*(text: cstring; fontSize: int32): int32 {.RLAPI, importc: "MeasureText".} # Measure string width for default font
proc MeasureTextEx*(font: Font; text: cstring; fontSize: float32; spacing: float32): Vector2 {.RLAPI, importc: "MeasureTextEx".} # Measure string size for Font
proc GetGlyphIndex*(font: Font; codepoint: int32): int32 {.RLAPI, importc: "GetGlyphIndex".} # Get index position for a unicode character on font
# Text strings management functions (no utf8 strings, only byte chars)
# NOTE: Some strings allocate memory internally for returned strings, just be careful!
proc TextCopy*(dst: ptr char; src: cstring): int32 {.RLAPI, importc: "TextCopy".} # Copy one string to another, returns bytes copied
proc TextIsEqual*(text1: cstring; text2: cstring): bool {.RLAPI, importc: "TextIsEqual".} # Check if two text string are equal
proc TextLength*(text: cstring): uint32 {.RLAPI, importc: "TextLength".} # Get text length, checks for '\0' ending
proc TextFormat*(text: cstring): cstring {.RLAPI, varargs, importc: "TextFormat".} # Text formatting with variables (sprintf style)
proc TextSubtext*(text: cstring; position: int32; length: int32): cstring {.RLAPI, importc: "TextSubtext".} # Get a piece of a text string
proc TextReplace*(text: ptr char; replace: cstring; by: cstring): ptr char {.RLAPI, importc: "TextReplace".} # Replace text string (memory must be freed!)
proc TextInsert*(text: cstring; insert: cstring; position: int32): ptr char {.RLAPI, importc: "TextInsert".} # Insert text in a position (memory must be freed!)
proc TextJoin*(textList: cstring; count: int32; delimiter: cstring): cstring {.RLAPI, importc: "TextJoin".} # Join text strings with delimiter
proc TextSplit*(text: cstring; delimiter: char; count: pointer): cstring {.RLAPI, importc: "TextSplit".} # Split text into multiple strings
proc TextAppend*(text: ptr char; append: cstring; position: pointer) {.RLAPI, importc: "TextAppend".} # Append text at specific position and move cursor!
proc TextFindIndex*(text: cstring; find: cstring): int32 {.RLAPI, importc: "TextFindIndex".} # Find first text occurrence within a string
proc TextToUpper*(text: cstring): cstring {.RLAPI, importc: "TextToUpper".} # Get upper case version of provided string
proc TextToLower*(text: cstring): cstring {.RLAPI, importc: "TextToLower".} # Get lower case version of provided string
proc TextToPascal*(text: cstring): cstring {.RLAPI, importc: "TextToPascal".} # Get Pascal case notation version of provided string
proc TextToInteger*(text: cstring): int32 {.RLAPI, importc: "TextToInteger".} # Get integer value from text (negative values not supported)
proc TextToUtf8*(codepoints: pointer; length: int32): ptr char {.RLAPI, importc: "TextToUtf8".} # Encode text codepoint into utf8 text (memory must be freed!)
# UTF8 text strings management functions
proc GetCodepoints*(text: cstring; count: pointer): pointer {.RLAPI, importc: "GetCodepoints".} # Get all codepoints in a string, codepoints count returned by parameters
proc GetCodepointsCount*(text: cstring): int32 {.RLAPI, importc: "GetCodepointsCount".} # Get total number of characters (codepoints) in a UTF8 encoded string
proc GetNextCodepoint*(text: cstring; bytesProcessed: pointer): int32 {.RLAPI, importc: "GetNextCodepoint".} # Returns next codepoint in a UTF8 encoded string; 0x3f('?') is returned on failure
proc CodepointToUtf8*(codepoint: int32; byteLength: pointer): cstring {.RLAPI, importc: "CodepointToUtf8".} # Encode codepoint into utf8 text (char array length returned as parameter)
# ------------------------------------------------------------------------------------
# Basic 3d Shapes Drawing Functions (Module: models)
# ------------------------------------------------------------------------------------
# Basic geometric 3D shapes drawing functions
proc DrawLine3D*(startPos: Vector3; endPos: Vector3; color: Color) {.RLAPI, importc: "DrawLine3D".} # Draw a line in 3D world space
proc DrawPoint3D*(position: Vector3; color: Color) {.RLAPI, importc: "DrawPoint3D".} # Draw a point in 3D space, actually a small line
proc DrawCircle3D*(center: Vector3; radius: float32; rotationAxis: Vector3; rotationAngle: float32; color: Color) {.RLAPI, importc: "DrawCircle3D".} # Draw a circle in 3D world space
proc DrawCube*(position: Vector3; width: float32; height: float32; length: float32; color: Color) {.RLAPI, importc: "DrawCube".} # Draw cube
proc DrawCubeV*(position: Vector3; size: Vector3; color: Color) {.RLAPI, importc: "DrawCubeV".} # Draw cube (Vector version)
proc DrawCubeWires*(position: Vector3; width: float32; height: float32; length: float32; color: Color) {.RLAPI, importc: "DrawCubeWires".} # Draw cube wires
proc DrawCubeWiresV*(position: Vector3; size: Vector3; color: Color) {.RLAPI, importc: "DrawCubeWiresV".} # Draw cube wires (Vector version)
proc DrawCubeTexture*(texture: Texture2D; position: Vector3; width: float32; height: float32; length: float32; color: Color) {.RLAPI, importc: "DrawCubeTexture".} # Draw cube textured
proc DrawSphere*(centerPos: Vector3; radius: float32; color: Color) {.RLAPI, importc: "DrawSphere".} # Draw sphere
proc DrawSphereEx*(centerPos: Vector3; radius: float32; rings: int32; slices: int32; color: Color) {.RLAPI, importc: "DrawSphereEx".} # Draw sphere with extended parameters
proc DrawSphereWires*(centerPos: Vector3; radius: float32; rings: int32; slices: int32; color: Color) {.RLAPI, importc: "DrawSphereWires".} # Draw sphere wires
proc DrawCylinder*(position: Vector3; radiusTop: float32; radiusBottom: float32; height: float32; slices: int32; color: Color) {.RLAPI, importc: "DrawCylinder".} # Draw a cylinder/cone
proc DrawCylinderWires*(position: Vector3; radiusTop: float32; radiusBottom: float32; height: float32; slices: int32; color: Color) {.RLAPI, importc: "DrawCylinderWires".} # Draw a cylinder/cone wires
proc DrawPlane*(centerPos: Vector3; size: Vector2; color: Color) {.RLAPI, importc: "DrawPlane".} # Draw a plane XZ
proc DrawRay*(ray: Ray; color: Color) {.RLAPI, importc: "DrawRay".} # Draw a ray line
proc DrawGrid*(slices: int32; spacing: float32) {.RLAPI, importc: "DrawGrid".} # Draw a grid (centered at (0, 0, 0))
proc DrawGizmo*(position: Vector3) {.RLAPI, importc: "DrawGizmo".} # Draw simple gizmo
# DrawTorus(), DrawTeapot() could be useful?
# ------------------------------------------------------------------------------------
# Model 3d Loading and Drawing Functions (Module: models)
# ------------------------------------------------------------------------------------
# Model loading/unloading functions
proc LoadModel*(fileName: cstring): Model {.RLAPI, importc: "LoadModel".} # Load model from files (meshes and materials)
proc LoadModelFromMesh*(mesh: Mesh): Model {.RLAPI, importc: "LoadModelFromMesh".} # Load model from generated mesh (default material)
proc UnloadModel*(model: Model) {.RLAPI, importc: "UnloadModel".} # Unload model from memory (RAM and/or VRAM)
# Mesh loading/unloading functions
proc LoadMeshes*(fileName: cstring; meshCount: pointer): ptr Mesh {.RLAPI, importc: "LoadMeshes".} # Load meshes from model file
proc ExportMesh*(mesh: Mesh; fileName: cstring) {.RLAPI, importc: "ExportMesh".} # Export mesh data to file
proc UnloadMesh*(mesh: Mesh) {.RLAPI, importc: "UnloadMesh".} # Unload mesh from memory (RAM and/or VRAM)
# Material loading/unloading functions
proc LoadMaterials*(fileName: cstring; materialCount: pointer): ptr Material {.RLAPI, importc: "LoadMaterials".} # Load materials from model file
proc LoadMaterialDefault*(): Material {.RLAPI, importc: "LoadMaterialDefault".} # Load default material (Supports: DIFFUSE, SPECULAR, NORMAL maps)
proc UnloadMaterial*(material: Material) {.RLAPI, importc: "UnloadMaterial".} # Unload material from GPU memory (VRAM)
proc SetMaterialTexture*(material: ptr Material; mapType: int32; texture: Texture2D) {.RLAPI, importc: "SetMaterialTexture".} # Set texture for a material map type (MAP_DIFFUSE, MAP_SPECULAR...)
proc SetModelMeshMaterial*(model: ptr Model; meshId: int32; materialId: int32) {.RLAPI, importc: "SetModelMeshMaterial".} # Set material for a mesh
# Model animations loading/unloading functions
proc LoadModelAnimations*(fileName: cstring; animsCount: pointer): ptr ModelAnimation {.RLAPI, importc: "LoadModelAnimations".} # Load model animations from file
proc UpdateModelAnimation*(model: Model; anim: ModelAnimation; frame: int32) {.RLAPI, importc: "UpdateModelAnimation".} # Update model animation pose
proc UnloadModelAnimation*(anim: ModelAnimation) {.RLAPI, importc: "UnloadModelAnimation".} # Unload animation data
proc IsModelAnimationValid*(model: Model; anim: ModelAnimation): bool {.RLAPI, importc: "IsModelAnimationValid".} # Check model animation skeleton match
# Mesh generation functions
proc GenMeshPoly*(sides: int32; radius: float32): Mesh {.RLAPI, importc: "GenMeshPoly".} # Generate polygonal mesh
proc GenMeshPlane*(width: float32; length: float32; resX: int32; resZ: int32): Mesh {.RLAPI, importc: "GenMeshPlane".} # Generate plane mesh (with subdivisions)
proc GenMeshCube*(width: float32; height: float32; length: float32): Mesh {.RLAPI, importc: "GenMeshCube".} # Generate cuboid mesh
proc GenMeshSphere*(radius: float32; rings: int32; slices: int32): Mesh {.RLAPI, importc: "GenMeshSphere".} # Generate sphere mesh (standard sphere)
proc GenMeshHemiSphere*(radius: float32; rings: int32; slices: int32): Mesh {.RLAPI, importc: "GenMeshHemiSphere".} # Generate half-sphere mesh (no bottom cap)
proc GenMeshCylinder*(radius: float32; height: float32; slices: int32): Mesh {.RLAPI, importc: "GenMeshCylinder".} # Generate cylinder mesh
proc GenMeshTorus*(radius: float32; size: float32; radSeg: int32; sides: int32): Mesh {.RLAPI, importc: "GenMeshTorus".} # Generate torus mesh
proc GenMeshKnot*(radius: float32; size: float32; radSeg: int32; sides: int32): Mesh {.RLAPI, importc: "GenMeshKnot".} # Generate trefoil knot mesh
proc GenMeshHeightmap*(heightmap: Image; size: Vector3): Mesh {.RLAPI, importc: "GenMeshHeightmap".} # Generate heightmap mesh from image data
proc GenMeshCubicmap*(cubicmap: Image; cubeSize: Vector3): Mesh {.RLAPI, importc: "GenMeshCubicmap".} # Generate cubes-based map mesh from image data
# Mesh manipulation functions
proc MeshBoundingBox*(mesh: Mesh): BoundingBox {.RLAPI, importc: "MeshBoundingBox".} # Compute mesh bounding box limits
proc MeshTangents*(mesh: ptr Mesh) {.RLAPI, importc: "MeshTangents".} # Compute mesh tangents
proc MeshBinormals*(mesh: ptr Mesh) {.RLAPI, importc: "MeshBinormals".} # Compute mesh binormals
# Model drawing functions
proc DrawModel*(model: Model; position: Vector3; scale: float32; tint: Color) {.RLAPI, importc: "DrawModel".} # Draw a model (with texture if set)
proc DrawModelEx*(model: Model; position: Vector3; rotationAxis: Vector3; rotationAngle: float32; scale: Vector3; tint: Color) {.RLAPI, importc: "DrawModelEx".} # Draw a model with extended parameters
proc DrawModelWires*(model: Model; position: Vector3; scale: float32; tint: Color) {.RLAPI, importc: "DrawModelWires".} # Draw a model wires (with texture if set)
proc DrawModelWiresEx*(model: Model; position: Vector3; rotationAxis: Vector3; rotationAngle: float32; scale: Vector3; tint: Color) {.RLAPI, importc: "DrawModelWiresEx".} # Draw a model wires (with texture if set) with extended parameters
proc DrawBoundingBox*(box: BoundingBox; color: Color) {.RLAPI, importc: "DrawBoundingBox".} # Draw bounding box (wires)
proc DrawBillboard*(camera: Camera; texture: Texture2D; center: Vector3; size: float32; tint: Color) {.RLAPI, importc: "DrawBillboard".} # Draw a billboard texture
proc DrawBillboardRec*(camera: Camera; texture: Texture2D; sourceRec: Rectangle; center: Vector3; size: float32; tint: Color) {.RLAPI, importc: "DrawBillboardRec".} # Draw a billboard texture defined by sourceRec
# Collision detection functions
proc CheckCollisionSpheres*(centerA: Vector3; radiusA: float32; centerB: Vector3; radiusB: float32): bool {.RLAPI, importc: "CheckCollisionSpheres".} # Detect collision between two spheres
proc CheckCollisionBoxes*(box1: BoundingBox; box2: BoundingBox): bool {.RLAPI, importc: "CheckCollisionBoxes".} # Detect collision between two bounding boxes
proc CheckCollisionBoxSphere*(box: BoundingBox; center: Vector3; radius: float32): bool {.RLAPI, importc: "CheckCollisionBoxSphere".} # Detect collision between box and sphere
proc CheckCollisionRaySphere*(ray: Ray; center: Vector3; radius: float32): bool {.RLAPI, importc: "CheckCollisionRaySphere".} # Detect collision between ray and sphere
proc CheckCollisionRaySphereEx*(ray: Ray; center: Vector3; radius: float32; collisionPoint: ptr Vector3): bool {.RLAPI, importc: "CheckCollisionRaySphereEx".} # Detect collision between ray and sphere, returns collision point
proc CheckCollisionRayBox*(ray: Ray; box: BoundingBox): bool {.RLAPI, importc: "CheckCollisionRayBox".} # Detect collision between ray and box
proc GetCollisionRayModel*(ray: Ray; model: Model): RayHitInfo {.RLAPI, importc: "GetCollisionRayModel".} # Get collision info between ray and model
proc GetCollisionRayTriangle*(ray: Ray; p1: Vector3; p2: Vector3; p3: Vector3): RayHitInfo {.RLAPI, importc: "GetCollisionRayTriangle".} # Get collision info between ray and triangle
proc GetCollisionRayGround*(ray: Ray; groundHeight: float32): RayHitInfo {.RLAPI, importc: "GetCollisionRayGround".} # Get collision info between ray and ground plane (Y-normal plane)
# ------------------------------------------------------------------------------------
# Shaders System Functions (Module: rlgl)
# NOTE: This functions are useless when using OpenGL 1.1
# ------------------------------------------------------------------------------------
# Shader loading/unloading functions
proc LoadText*(fileName: cstring): ptr char {.RLAPI, importc: "LoadText".} # Load chars array from text file
proc LoadShader*(vsFileName: cstring; fsFileName: cstring): Shader {.RLAPI, importc: "LoadShader".} # Load shader from files and bind default locations
proc LoadShaderCode*(vsCode: cstring; fsCode: cstring): Shader {.RLAPI, importc: "LoadShaderCode".} # Load shader from code strings and bind default locations
proc UnloadShader*(shader: Shader) {.RLAPI, importc: "UnloadShader".} # Unload shader from GPU memory (VRAM)
proc GetShaderDefault*(): Shader {.RLAPI, importc: "GetShaderDefault".} # Get default shader
proc GetTextureDefault*(): Texture2D {.RLAPI, importc: "GetTextureDefault".} # Get default texture
proc GetShapesTexture*(): Texture2D {.RLAPI, importc: "GetShapesTexture".} # Get texture to draw shapes
proc GetShapesTextureRec*(): Rectangle {.RLAPI, importc: "GetShapesTextureRec".} # Get texture rectangle to draw shapes
proc SetShapesTexture*(texture: Texture2D; source: Rectangle) {.RLAPI, importc: "SetShapesTexture".} # Define default texture used to draw shapes
# Shader configuration functions
proc GetShaderLocation*(shader: Shader; uniformName: cstring): int32 {.RLAPI, importc: "GetShaderLocation".} # Get shader uniform location
proc SetShaderValue*(shader: Shader; uniformLoc: int32; value: pointer; uniformType: int32) {.RLAPI, importc: "SetShaderValue".} # Set shader uniform value
proc SetShaderValueV*(shader: Shader; uniformLoc: int32; value: pointer; uniformType: int32; count: int32) {.RLAPI, importc: "SetShaderValueV".} # Set shader uniform value vector
proc SetShaderValueMatrix*(shader: Shader; uniformLoc: int32; mat: Matrix) {.RLAPI, importc: "SetShaderValueMatrix".} # Set shader uniform value (matrix 4x4)
proc SetShaderValueTexture*(shader: Shader; uniformLoc: int32; texture: Texture2D) {.RLAPI, importc: "SetShaderValueTexture".} # Set shader uniform value for texture
proc SetMatrixProjection*(proj: Matrix) {.RLAPI, importc: "SetMatrixProjection".} # Set a custom projection matrix (replaces internal projection matrix)
proc SetMatrixModelview*(view: Matrix) {.RLAPI, importc: "SetMatrixModelview".} # Set a custom modelview matrix (replaces internal modelview matrix)
proc GetMatrixModelview*(): Matrix {.RLAPI, importc: "GetMatrixModelview".} # Get internal modelview matrix
proc GetMatrixProjection*(): Matrix {.RLAPI, importc: "GetMatrixProjection".} # Get internal projection matrix
# Texture maps generation (PBR)
# NOTE: Required shaders should be provided
proc GenTextureCubemap*(shader: Shader; map: Texture2D; size: int32): Texture2D {.RLAPI, importc: "GenTextureCubemap".} # Generate cubemap texture from 2D texture
proc GenTextureIrradiance*(shader: Shader; cubemap: Texture2D; size: int32): Texture2D {.RLAPI, importc: "GenTextureIrradiance".} # Generate irradiance texture using cubemap data
proc GenTexturePrefilter*(shader: Shader; cubemap: Texture2D; size: int32): Texture2D {.RLAPI, importc: "GenTexturePrefilter".} # Generate prefilter texture using cubemap data
proc GenTextureBRDF*(shader: Shader; size: int32): Texture2D {.RLAPI, importc: "GenTextureBRDF".} # Generate BRDF texture
# Shading begin/end functions
proc BeginShaderMode*(shader: Shader) {.RLAPI, importc: "BeginShaderMode".} # Begin custom shader drawing
proc EndShaderMode*() {.RLAPI, importc: "EndShaderMode".} # End custom shader drawing (use default shader)
proc BeginBlendMode*(mode: int32) {.RLAPI, importc: "BeginBlendMode".} # Begin blending mode (alpha, additive, multiplied)
proc EndBlendMode*() {.RLAPI, importc: "EndBlendMode".} # End blending mode (reset to default: alpha blending)
# VR control functions
proc InitVrSimulator*() {.RLAPI, importc: "InitVrSimulator".} # Init VR simulator for selected device parameters
proc CloseVrSimulator*() {.RLAPI, importc: "CloseVrSimulator".} # Close VR simulator for current device
proc UpdateVrTracking*(camera: ptr Camera) {.RLAPI, importc: "UpdateVrTracking".} # Update VR tracking (position and orientation) and camera
proc SetVrConfiguration*(info: VrDeviceInfo; distortion: Shader) {.RLAPI, importc: "SetVrConfiguration".} # Set stereo rendering configuration parameters
proc IsVrSimulatorReady*(): bool {.RLAPI, importc: "IsVrSimulatorReady".} # Detect if VR simulator is ready
proc ToggleVrMode*() {.RLAPI, importc: "ToggleVrMode".} # Enable/Disable VR experience
proc BeginVrDrawing*() {.RLAPI, importc: "BeginVrDrawing".} # Begin VR simulator stereo rendering
proc EndVrDrawing*() {.RLAPI, importc: "EndVrDrawing".} # End VR simulator stereo rendering
# ------------------------------------------------------------------------------------
# Audio Loading and Playing Functions (Module: audio)
# ------------------------------------------------------------------------------------
# Audio device management functions
proc InitAudioDevice*() {.RLAPI, importc: "InitAudioDevice".} # Initialize audio device and context
proc CloseAudioDevice*() {.RLAPI, importc: "CloseAudioDevice".} # Close the audio device and context
proc IsAudioDeviceReady*(): bool {.RLAPI, importc: "IsAudioDeviceReady".} # Check if audio device has been initialized successfully
proc SetMasterVolume*(volume: float32) {.RLAPI, importc: "SetMasterVolume".} # Set master volume (listener)
# Wave/Sound loading/unloading functions
proc LoadWave*(fileName: cstring): Wave {.RLAPI, importc: "LoadWave".} # Load wave data from file
proc LoadSound*(fileName: cstring): Sound {.RLAPI, importc: "LoadSound".} # Load sound from file
proc LoadSoundFromWave*(wave: Wave): Sound {.RLAPI, importc: "LoadSoundFromWave".} # Load sound from wave data
proc UpdateSound*(sound: Sound; data: pointer; samplesCount: int32) {.RLAPI, importc: "UpdateSound".} # Update sound buffer with new data
proc UnloadWave*(wave: Wave) {.RLAPI, importc: "UnloadWave".} # Unload wave data
proc UnloadSound*(sound: Sound) {.RLAPI, importc: "UnloadSound".} # Unload sound
proc ExportWave*(wave: Wave; fileName: cstring) {.RLAPI, importc: "ExportWave".} # Export wave data to file
proc ExportWaveAsCode*(wave: Wave; fileName: cstring) {.RLAPI, importc: "ExportWaveAsCode".} # Export wave sample data to code (.h)
# Wave/Sound management functions
proc PlaySound*(sound: Sound) {.RLAPI, importc: "PlaySound".} # Play a sound
proc StopSound*(sound: Sound) {.RLAPI, importc: "StopSound".} # Stop playing a sound
proc PauseSound*(sound: Sound) {.RLAPI, importc: "PauseSound".} # Pause a sound
proc ResumeSound*(sound: Sound) {.RLAPI, importc: "ResumeSound".} # Resume a paused sound
proc PlaySoundMulti*(sound: Sound) {.RLAPI, importc: "PlaySoundMulti".} # Play a sound (using multichannel buffer pool)
proc StopSoundMulti*() {.RLAPI, importc: "StopSoundMulti".} # Stop any sound playing (using multichannel buffer pool)
proc GetSoundsPlaying*(): int32 {.RLAPI, importc: "GetSoundsPlaying".} # Get number of sounds playing in the multichannel
proc IsSoundPlaying*(sound: Sound): bool {.RLAPI, importc: "IsSoundPlaying".} # Check if a sound is currently playing
proc SetSoundVolume*(sound: Sound; volume: float32) {.RLAPI, importc: "SetSoundVolume".} # Set volume for a sound (1.0 is max level)
proc SetSoundPitch*(sound: Sound; pitch: float32) {.RLAPI, importc: "SetSoundPitch".} # Set pitch for a sound (1.0 is base level)
proc WaveFormat*(wave: ptr Wave; sampleRate: int32; sampleSize: int32; channels: int32) {.RLAPI, importc: "WaveFormat".} # Convert wave data to desired format
proc WaveCopy*(wave: Wave): Wave {.RLAPI, importc: "WaveCopy".} # Copy a wave to a new wave
proc WaveCrop*(wave: ptr Wave; initSample: int32; finalSample: int32) {.RLAPI, importc: "WaveCrop".} # Crop a wave to defined samples range
proc GetWaveData*(wave: Wave): float32 {.RLAPI, importc: "GetWaveData".} # Get samples data from wave as a floats array
# Music management functions
proc LoadMusicStream*(fileName: cstring): Music {.RLAPI, importc: "LoadMusicStream".} # Load music stream from file
proc UnloadMusicStream*(music: Music) {.RLAPI, importc: "UnloadMusicStream".} # Unload music stream
proc PlayMusicStream*(music: Music) {.RLAPI, importc: "PlayMusicStream".} # Start music playing
proc UpdateMusicStream*(music: Music) {.RLAPI, importc: "UpdateMusicStream".} # Updates buffers for music streaming
proc StopMusicStream*(music: Music) {.RLAPI, importc: "StopMusicStream".} # Stop music playing
proc PauseMusicStream*(music: Music) {.RLAPI, importc: "PauseMusicStream".} # Pause music playing
proc ResumeMusicStream*(music: Music) {.RLAPI, importc: "ResumeMusicStream".} # Resume playing paused music
proc IsMusicPlaying*(music: Music): bool {.RLAPI, importc: "IsMusicPlaying".} # Check if music is playing
proc SetMusicVolume*(music: Music; volume: float32) {.RLAPI, importc: "SetMusicVolume".} # Set volume for music (1.0 is max level)
proc SetMusicPitch*(music: Music; pitch: float32) {.RLAPI, importc: "SetMusicPitch".} # Set pitch for a music (1.0 is base level)
proc SetMusicLoopCount*(music: Music; count: int32) {.RLAPI, importc: "SetMusicLoopCount".} # Set music loop count (loop repeats)
proc GetMusicTimeLength*(music: Music): float32 {.RLAPI, importc: "GetMusicTimeLength".} # Get music time length (in seconds)
proc GetMusicTimePlayed*(music: Music): float32 {.RLAPI, importc: "GetMusicTimePlayed".} # Get current music time played (in seconds)
# AudioStream management functions
proc InitAudioStream*(sampleRate: uint32; sampleSize: uint32; channels: uint32): AudioStream {.RLAPI, importc: "InitAudioStream".} # Init audio stream (to stream raw audio pcm data)
proc UpdateAudioStream*(stream: AudioStream; data: pointer; samplesCount: int32) {.RLAPI, importc: "UpdateAudioStream".} # Update audio stream buffers with data
proc CloseAudioStream*(stream: AudioStream) {.RLAPI, importc: "CloseAudioStream".} # Close audio stream and free memory
proc IsAudioStreamProcessed*(stream: AudioStream): bool {.RLAPI, importc: "IsAudioStreamProcessed".} # Check if any audio stream buffers requires refill
proc PlayAudioStream*(stream: AudioStream) {.RLAPI, importc: "PlayAudioStream".} # Play audio stream
proc PauseAudioStream*(stream: AudioStream) {.RLAPI, importc: "PauseAudioStream".} # Pause audio stream
proc ResumeAudioStream*(stream: AudioStream) {.RLAPI, importc: "ResumeAudioStream".} # Resume audio stream
proc IsAudioStreamPlaying*(stream: AudioStream): bool {.RLAPI, importc: "IsAudioStreamPlaying".} # Check if audio stream is playing
proc StopAudioStream*(stream: AudioStream) {.RLAPI, importc: "StopAudioStream".} # Stop audio stream
proc SetAudioStreamVolume*(stream: AudioStream; volume: float32) {.RLAPI, importc: "SetAudioStreamVolume".} # Set volume for audio stream (1.0 is max level)
proc SetAudioStreamPitch*(stream: AudioStream; pitch: float32) {.RLAPI, importc: "SetAudioStreamPitch".} # Set pitch for audio stream (1.0 is base level)
# ------------------------------------------------------------------------------------
# Network (Module: network)
# ------------------------------------------------------------------------------------
# IN PROGRESS: Check rnet.h for reference
