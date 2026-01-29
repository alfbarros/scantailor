INCLUDE_DIRECTORIES(BEFORE ..)

SET(
	sources
	main.cpp TestContentSpanFinder.cpp
	TestSmartFilenameOrdering.cpp
	TestMatrixCalc.cpp
	../ContentSpanFinder.cpp ../ContentSpanFinder.h
	../SmartFilenameOrdering.cpp ../SmartFilenameOrdering.h
)

SOURCE_GROUP("Sources" FILES ${sources})

SET(
	libs
	imageproc math ${Boost_UNIT_TEST_FRAMEWORK_LIBRARY}
	${Boost_PRG_EXECUTION_MONITOR_LIBRARY}
	${QT_QTGUI_LIBRARY} ${QT_QTCORE_LIBRARY} ${EXTRA_LIBS}
)

ADD_EXECUTABLE(tests ${sources})
TARGET_LINK_LIBRARIES(tests PUBLIC ${libs})

TARGET_LINK_LIBRARIES(tests PUBLIC Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Xml)
SET_TARGET_PROPERTIES(tests PROPERTIES AUTOMOC ON AUTOUIC ON)
SET_TARGET_PROPERTIES(tests PROPERTIES AUTOUIC_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/ui")