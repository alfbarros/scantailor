PROJECT("Page Split Filter")

INCLUDE_DIRECTORIES(BEFORE "${CMAKE_CURRENT_BINARY_DIR}")

FILE(GLOB ui_files "ui/*.ui")

SET_SOURCE_FILES_PROPERTIES(${ui_files} PROPERTIES GENERATED TRUE)
SOURCE_GROUP("UI Files" FILES ${ui_files})
SOURCE_GROUP("Generated" FILES ${ui_files})

SET(
	sources
	SplitLineObject.h
	ImageView.cpp ImageView.h
	Thumbnail.cpp Thumbnail.h
	Params.cpp Params.h
	Dependencies.cpp Dependencies.h
	PageLayout.cpp PageLayout.h
	PageLayoutEstimator.cpp PageLayoutEstimator.h
	VertLineFinder.cpp VertLineFinder.h
	Filter.cpp Filter.h
	OptionsWidget.cpp OptionsWidget.h
	SplitModeDialog.cpp SplitModeDialog.h
	Settings.cpp Settings.h
	Task.cpp Task.h
	CacheDrivenTask.cpp CacheDrivenTask.h
	LayoutType.cpp LayoutType.h
	UnremoveButton.cpp UnremoveButton.h
	OrderBySplitTypeProvider.cpp OrderBySplitTypeProvider.h
)
SOURCE_GROUP("Sources" FILES ${sources})


ADD_LIBRARY(page_split STATIC ${sources} ${ui_files})


TARGET_LINK_LIBRARIES(page_split PUBLIC Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Xml Qt6::OpenGLWidgets)
SET_TARGET_PROPERTIES(page_split PROPERTIES AUTOMOC ON AUTOUIC ON)
SET_TARGET_PROPERTIES(page_split PROPERTIES AUTOUIC_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/ui")