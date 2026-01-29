CMAKE_MINIMUM_REQUIRED(VERSION 3.16)

PROJECT("Scan Tailor" LANGUAGES CXX C)

SET(CMAKE_CXX_STANDARD 17)
SET(CMAKE_CXX_STANDARD_REQUIRED ON)
SET(CMAKE_CXX_EXTENSIONS OFF)

# Suppress warnings.
IF(COMMAND cmake_policy)
	cmake_policy(SET CMP0003 NEW)
ENDIF(COMMAND cmake_policy)

SET(
	CMAKE_USER_MAKE_RULES_OVERRIDE
	"${CMAKE_SOURCE_DIR}/cmake/default_cflags.cmake"
)
SET(
	CMAKE_USER_MAKE_RULES_OVERRIDE_CXX
	"${CMAKE_SOURCE_DIR}/cmake/default_cxxflags.cmake"
)

# This forces Visual Studio 2008 SP1 to actually link to the versions of the
# libraries it ships with!  It's harmless on other platforms.
ADD_DEFINITIONS(-D_BIND_TO_CURRENT_VCLIBS_VERSION=1)

IF(DEBUG_CLI)
	ADD_DEFINITIONS(-DDEBUG_CLI)
ENDIF(DEBUG_CLI)

ENABLE_TESTING()

# An undocumented side-effect of CONFIGURE_FILE() is that it makes
# the whole project depend on the file we are parsing / copying.
CONFIGURE_FILE(
	"${PROJECT_SOURCE_DIR}/version.h"
	"${PROJECT_BINARY_DIR}/.version.h" COPYONLY
)

# Prevent this leftover from old builds to be used in favour
# of the one in ${PROJECT_SOURCE_DIR}
IF(NOT "${PROJECT_BINARY_DIR}" STREQUAL "${PROJECT_SOURCE_DIR}")
	FILE(REMOVE "${PROJECT_BINARY_DIR}/version.h")
ENDIF()

# Extract VERSION and VERSION_QUAD from version.h
FILE(READ "${PROJECT_SOURCE_DIR}/version.h" version_h_contents)
STRING(
	REGEX REPLACE
	".*#define[ \\t]+VERSION[ \\t]+\"([^\"]*)\".*"
	"\\1" VERSION "${version_h_contents}"
)
IF("${VERSION}" STREQUAL "${version_h_contents}")
	MESSAGE(FATAL_ERROR "Failed to extract VERSION from version.h")
ENDIF()

# VERSION_QUAD must be either empty or be in the form of X.Y.Z.Y
STRING(
	REGEX REPLACE
	".*#define[ \\t]+VERSION_QUAD[ \\t]+\"(([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)?)\".*"
	"\\1" VERSION_QUAD "${version_h_contents}"
)
IF("${VERSION_QUAD}" STREQUAL "${version_h_contents}")
	MESSAGE(FATAL_ERROR "Failed to extract VERSION_QUAD from version.h")
ENDIF()

# This has to go quite early on, as otherwise we risk picking
# up an identically named header from a system include path.
INCLUDE_DIRECTORIES(. foundation math interaction zones)

INCLUDE(CheckIncludeFile)
INCLUDE(CheckIncludeFileCXX)
INCLUDE(TestCXXAcceptsFlag)
# INCLUDE(FindBoost) # Built-in in newer CMake
INCLUDE(cmake/FindPthreads.cmake)
INCLUDE(cmake/SetDefaultBuildType.cmake)
INCLUDE(cmake/SetDefaultGccFlags.cmake)
INCLUDE(cmake/ToNativePath.cmake)
# INCLUDE(cmake/UpdateTranslations.cmake) # Using Qt6 standard way
INCLUDE(cmake/CopyToBuildDir.cmake)
INCLUDE(cmake/LibToDLL.cmake)

ST_SET_DEFAULT_BUILD_TYPE(Release)
IF(CMAKE_COMPILER_IS_GNUCC)
	ST_SET_DEFAULT_GCC_FLAGS()
ENDIF(CMAKE_COMPILER_IS_GNUCC)

FIND_PACKAGE(Qt6 REQUIRED COMPONENTS Core Gui Widgets Xml OpenGLWidgets Network LinguistTools)
FIND_PACKAGE(Boost REQUIRED COMPONENTS unit_test_framework prg_exec_monitor)
FIND_PACKAGE(JPEG REQUIRED)
FIND_PACKAGE(ZLIB REQUIRED)
FIND_PACKAGE(PNG REQUIRED)
FIND_PACKAGE(TIFF REQUIRED)
FIND_PACKAGE(OpenGL REQUIRED)

INCLUDE_DIRECTORIES(${Boost_INCLUDE_DIRS})
LINK_DIRECTORIES(${Boost_LIBRARY_DIRS})

INCLUDE_DIRECTORIES(${JPEG_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${ZLIB_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${PNG_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${TIFF_INCLUDE_DIR})

IF(UNIX)
	# We need to manually use XRender.
	# FIND_PACKAGE(X11)
	# INCLUDE_DIRECTORIES("${X11_Xrender_INCLUDE_PATH}")

	FindPthreads()
	IF(PTHREADS_FOUND)
		ADD_DEFINITIONS(${PTHREADS_CFLAGS})
		LINK_LIBRARIES(${PTHREADS_LIBS})
	ENDIF(PTHREADS_FOUND)
ENDIF(UNIX)

CHECK_INCLUDE_FILE(stdint.h HAVE_STDINT_H)
IF(NOT HAVE_STDINT_H)
	CONFIGURE_FILE(compat/pstdint.h "${CMAKE_CURRENT_BINARY_DIR}/stdint.h" COPYONLY)
	INCLUDE_DIRECTORIES("${CMAKE_CURRENT_BINARY_DIR}")
ELSE(NOT HAVE_STDINT_H)
	FILE(REMOVE "${CMAKE_CURRENT_BINARY_DIR}/stdint.h")
ENDIF(NOT HAVE_STDINT_H)

ADD_DEFINITIONS(-DBOOST_MULTI_INDEX_DISABLE_SERIALIZATION)

# Prepare config.h
IF(WIN32)
	SET(TRANSLATIONS_DIR_REL "translations")
ELSE(WIN32)
	SET(TRANSLATIONS_DIR_REL "share/scantailor/translations")
ENDIF(WIN32)
SET(TRANSLATIONS_DIR_ABS "${CMAKE_INSTALL_PREFIX}/${TRANSLATIONS_DIR_REL}")

CONFIGURE_FILE(config.h.in ${CMAKE_BINARY_DIR}/config.h @ONLY)

IF(WIN32)
	# crash_reporter is included unconditionally to collect translation sources from there.
	ADD_SUBDIRECTORY(crash_reporter)
ENDIF()
ADD_SUBDIRECTORY(dewarping)
ADD_SUBDIRECTORY(foundation)
ADD_SUBDIRECTORY(math)
ADD_SUBDIRECTORY(imageproc)
ADD_SUBDIRECTORY(interaction)
ADD_SUBDIRECTORY(zones)
ADD_SUBDIRECTORY(tests)

FILE(GLOB common_ui_files ui/ErrorWidget.ui)
FILE(GLOB gui_only_ui_files "ui/*.ui")
FOREACH(ui_file ${common_ui_files})
	LIST(REMOVE_ITEM gui_only_ui_files "${ui_file}")
ENDFOREACH()

SOURCE_GROUP("UI Files" FILES ${common_ui_files} ${gui_only_ui_files})
# QT4_WRAP_UI replaced by AUTOUIC or explicit call if needed, but here handled by targets properties usually
# However, we need to generate headers for use in source.
# For main executable, we can just add .ui files to sources and set AUTOUIC.

ADD_SUBDIRECTORY(ui)
INCLUDE_DIRECTORIES("${CMAKE_CURRENT_BINARY_DIR}") # for ui files

ADD_SUBDIRECTORY(filters/fix_orientation)
ADD_SUBDIRECTORY(filters/page_split)
ADD_SUBDIRECTORY(filters/deskew)
ADD_SUBDIRECTORY(filters/select_content)
ADD_SUBDIRECTORY(filters/page_layout)
ADD_SUBDIRECTORY(filters/output)

SET(resource_sources resources/resources.qrc)
# QT4_ADD_RESOURCES(resource_sources resources/resources.qrc) -> handled by AUTORCC or adding .qrc to target

SET(
	common_sources
	BackgroundExecutor.cpp BackgroundExecutor.h
	OpenGLSupport.cpp OpenGLSupport.h
	PixmapRenderer.cpp PixmapRenderer.h
	BubbleAnimation.cpp BubbleAnimation.h
	ProcessingIndicationWidget.cpp ProcessingIndicationWidget.h
	NonOwningWidget.cpp NonOwningWidget.h
	Dpi.cpp Dpi.h Dpm.cpp Dpm.h
	SmartFilenameOrdering.cpp SmartFilenameOrdering.h
	AbstractRelinker.h
	RelinkablePath.cpp RelinkablePath.h
	ImageInfo.cpp ImageInfo.h
	ImageFileInfo.cpp ImageFileInfo.h
	ImageMetadata.cpp ImageMetadata.h
	RecentProjects.cpp RecentProjects.h
	OutOfMemoryHandler.cpp OutOfMemoryHandler.h
	CommandLine.cpp CommandLine.h
	PageSelectionAccessor.cpp PageSelectionAccessor.h
	PageSelectionProvider.h
	ContentSpanFinder.cpp ContentSpanFinder.h
	PhysicalTransformation.cpp PhysicalTransformation.h
	ImageTransformation.cpp ImageTransformation.h
	ImagePixmapUnion.h
	ImageViewBase.cpp ImageViewBase.h
	BasicImageView.cpp BasicImageView.h
	StageListView.cpp StageListView.h
	DebugImageView.cpp DebugImageView.h
	TabbedDebugImages.cpp TabbedDebugImages.h
	ThumbnailLoadResult.h
	ThumbnailPixmapCache.cpp ThumbnailPixmapCache.h
	ThumbnailBase.cpp ThumbnailBase.h
	ThumbnailFactory.cpp ThumbnailFactory.h
	IncompleteThumbnail.cpp IncompleteThumbnail.h
	ContentBoxPropagator.cpp ContentBoxPropagator.h
	PageOrientationPropagator.cpp PageOrientationPropagator.h
	DebugImages.cpp DebugImages.h
	ImageId.cpp ImageId.h
	PageId.cpp PageId.h
	PageInfo.cpp PageInfo.h
	BackgroundTask.cpp BackgroundTask.h
	ProcessingTaskQueue.cpp ProcessingTaskQueue.h
	PageSequence.cpp PageSequence.h
	StageSequence.cpp StageSequence.h
	ProjectPages.cpp ProjectPages.h
	FilterData.cpp FilterData.h
	ImageMetadataLoader.cpp ImageMetadataLoader.h
	TiffReader.cpp TiffReader.h
	TiffWriter.cpp TiffWriter.h
	PngMetadataLoader.cpp PngMetadataLoader.h
	TiffMetadataLoader.cpp TiffMetadataLoader.h
	JpegMetadataLoader.cpp JpegMetadataLoader.h
	ImageLoader.cpp ImageLoader.h
	ErrorWidget.cpp ErrorWidget.h
	OrthogonalRotation.cpp OrthogonalRotation.h
	WorkerThread.cpp WorkerThread.h
	LoadFileTask.cpp LoadFileTask.h
	FilterOptionsWidget.cpp FilterOptionsWidget.h
	TaskStatus.h FilterUiInterface.h
	ProjectReader.cpp ProjectReader.h
	ProjectWriter.cpp ProjectWriter.h
	XmlMarshaller.cpp XmlMarshaller.h
	XmlUnmarshaller.cpp XmlUnmarshaller.h
	AtomicFileOverwriter.cpp AtomicFileOverwriter.h
	EstimateBackground.cpp EstimateBackground.h
	Despeckle.cpp Despeckle.h
	ThreadPriority.cpp ThreadPriority.h
	FileNameDisambiguator.cpp FileNameDisambiguator.h
	OutputFileNameGenerator.cpp OutputFileNameGenerator.h
	PageRange.cpp PageRange.h
	SelectedPage.cpp SelectedPage.h
	Utils.cpp Utils.h
	PageView.h
	AutoManualMode.h
	AbstractCommand.h
	AbstractFilter.h
	BeforeOrAfter.h
	FilterResult.h
	CompositeCacheDrivenTask.h
	Margins.h
	ChangedStateItemDelegate.h
	PageOrderProvider.h
	PageOrderOption.h
	PayloadEvent.h
	filter_dc/AbstractFilterDataCollector.h
	filter_dc/ThumbnailCollector.h
	filter_dc/ContentBoxCollector.h
	filter_dc/PageOrientationCollector.h
	version.h
	config.h.in
)

SET(
	gui_only_sources
	Application.cpp Application.h
	SkinnedButton.cpp SkinnedButton.h
	RelinkablePathVisualization.cpp RelinkablePathVisualization.h
	RelinkingModel.cpp RelinkingModel.h
	RelinkingSortingModel.cpp RelinkingSortingModel.h
	RelinkingListView.cpp RelinkingListView.h
	RelinkingDialog.cpp RelinkingDialog.h
	SettingsDialog.cpp SettingsDialog.h
	FixDpiDialog.cpp FixDpiDialog.h
	LoadFilesStatusDialog.cpp LoadFilesStatusDialog.h
	ProjectCreationContext.cpp ProjectCreationContext.h
	ProjectOpeningContext.cpp ProjectOpeningContext.h
	OutOfMemoryDialog.cpp OutOfMemoryDialog.h
	ThumbnailSequence.cpp ThumbnailSequence.h
	ProjectFilesDialog.cpp ProjectFilesDialog.h
	NewOpenProjectPanel.cpp NewOpenProjectPanel.h
	SystemLoadWidget.cpp SystemLoadWidget.h
	MainWindow.cpp MainWindow.h
	main.cpp
)

SET(
	cli_only_sources
	ConsoleBatch.cpp ConsoleBatch.h
	main-cli.cpp
)

SOURCE_GROUP("Sources" FILES ${common_sources} ${gui_only_sources} ${cli_only_sources})
SOURCE_GROUP("Special Headers" FILES version.h config.h.in)

IF(CMAKE_COMPILER_IS_GNUCXX)
	SET_SOURCE_FILES_PROPERTIES(
		ThumbnailSequence.cpp PROPERTIES
		COMPILE_FLAGS "-fno-strict-aliasing"
	)
ENDIF()

ADD_LIBRARY(stcore STATIC ${common_sources} ${common_ui_files})
SET_TARGET_PROPERTIES(stcore PROPERTIES AUTOMOC ON AUTOUIC ON AUTORCC ON)
TARGET_LINK_LIBRARIES(stcore PUBLIC Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Xml Qt6::Network Qt6::OpenGLWidgets ${JPEG_LIBRARY} ${TIFF_LIBRARY} ${PNG_LIBRARY} ${ZLIB_LIBRARY})
SET_TARGET_PROPERTIES(stcore PROPERTIES AUTOUIC_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/ui")

ADD_EXECUTABLE(
	scantailor WIN32 ${gui_only_sources} ${common_ui_files} ${gui_only_ui_files}
	${resource_sources} resources/icons/COPYING
)
SET_TARGET_PROPERTIES(scantailor PROPERTIES AUTOMOC ON AUTOUIC ON AUTORCC ON)
SET_TARGET_PROPERTIES(scantailor PROPERTIES AUTOUIC_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/ui")

ADD_EXECUTABLE(scantailor-cli ${cli_only_sources} ${common_ui_files})
SET_TARGET_PROPERTIES(scantailor-cli PROPERTIES AUTOMOC ON AUTOUIC ON AUTORCC ON)
SET_TARGET_PROPERTIES(scantailor-cli PROPERTIES AUTOUIC_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/ui")

TARGET_LINK_LIBRARIES(
	scantailor
	fix_orientation page_split deskew select_content page_layout output stcore
	dewarping zones interaction imageproc math foundation
	Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Xml Qt6::OpenGLWidgets ${EXTRA_LIBS}
)
TARGET_LINK_LIBRARIES(
	scantailor-cli
	fix_orientation page_split deskew select_content page_layout output
	stcore dewarping zones interaction imageproc math foundation
	Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Xml Qt6::OpenGLWidgets ${EXTRA_LIBS}
)

INSTALL(TARGETS scantailor scantailor-cli RUNTIME DESTINATION bin)

# Translations
FILE(GLOB TRANSLATION_FILES translations/scantailor_*.ts)
qt6_add_translation(QM_FILES ${TRANSLATION_FILES})
ADD_CUSTOM_TARGET(compile_translations ALL DEPENDS ${QM_FILES})

INSTALL(FILES ${QM_FILES} DESTINATION "${TRANSLATIONS_DIR_REL}/")

# Tests
# ADD_TEST(ImageProcTests imageproc/tests/imageproc_tests --log_level=message)
# ADD_TEST(ScanTaylorTests tests/tests --log_level=message)
