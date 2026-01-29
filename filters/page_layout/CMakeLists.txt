PROJECT("Page Layout Filter")

INCLUDE_DIRECTORIES(BEFORE "${CMAKE_CURRENT_BINARY_DIR}")

FILE(GLOB ui_files "ui/*.ui")

SET_SOURCE_FILES_PROPERTIES(${ui_files} PROPERTIES GENERATED TRUE)
SOURCE_GROUP("UI Files" FILES ${ui_files})
SOURCE_GROUP("Generated" FILES ${ui_files})

SET(
	sources
	Utils.cpp Utils.h
	ImageView.cpp ImageView.h
	Filter.cpp Filter.h
	OptionsWidget.cpp OptionsWidget.h
	Task.cpp Task.h
	CacheDrivenTask.cpp CacheDrivenTask.h
	Params.cpp Params.h
	Settings.cpp Settings.h
	Thumbnail.cpp Thumbnail.h
	ApplyDialog.cpp ApplyDialog.h
	Alignment.cpp Alignment.h
	OrderByWidthProvider.cpp OrderByWidthProvider.h
	OrderByHeightProvider.cpp OrderByHeightProvider.h
)
SOURCE_GROUP("Sources" FILES ${sources})


ADD_LIBRARY(page_layout STATIC ${sources} ${ui_files})


TARGET_LINK_LIBRARIES(page_layout PUBLIC Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Xml Qt6::OpenGLWidgets)
SET_TARGET_PROPERTIES(page_layout PROPERTIES AUTOMOC ON AUTOUIC ON)
SET_TARGET_PROPERTIES(page_layout PROPERTIES AUTOUIC_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/ui")