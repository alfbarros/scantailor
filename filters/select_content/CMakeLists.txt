PROJECT("Select Content Filter")

INCLUDE_DIRECTORIES(BEFORE "${CMAKE_CURRENT_BINARY_DIR}")

FILE(GLOB ui_files "ui/*.ui")

SET_SOURCE_FILES_PROPERTIES(${ui_files} PROPERTIES GENERATED TRUE)
SOURCE_GROUP("UI Files" FILES ${ui_files})
SOURCE_GROUP("Generated" FILES ${ui_files})

SET(
	sources
	ImageView.cpp ImageView.h
	Filter.cpp Filter.h
	OptionsWidget.cpp OptionsWidget.h
	ApplyDialog.cpp ApplyDialog.h
	ContentBoxFinder.cpp ContentBoxFinder.h
	Task.cpp Task.h
	CacheDrivenTask.cpp CacheDrivenTask.h
	Dependencies.cpp Dependencies.h
	Params.cpp Params.h
	Settings.cpp Settings.h
	Thumbnail.cpp Thumbnail.h
	PhysSizeCalc.cpp PhysSizeCalc.h
	OrderByWidthProvider.cpp OrderByWidthProvider.h
	OrderByHeightProvider.cpp OrderByHeightProvider.h
)
SOURCE_GROUP("Sources" FILES ${sources})


ADD_LIBRARY(select_content STATIC ${sources} ${ui_files})



TARGET_LINK_LIBRARIES(select_content PUBLIC Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Xml Qt6::OpenGLWidgets)
SET_TARGET_PROPERTIES(select_content PROPERTIES AUTOMOC ON AUTOUIC ON)
SET_TARGET_PROPERTIES(select_content PROPERTIES AUTOUIC_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/ui")