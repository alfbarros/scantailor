PROJECT("Dewarping library")

SET(
	sources
	Curve.cpp Curve.h
	DistortionModel.cpp DistortionModel.h
	DistortionModelBuilder.cpp DistortionModelBuilder.h
	DetectVertContentBounds.cpp DetectVertContentBounds.h
	TowardsLineTracer.cpp TowardsLineTracer.h
	TextLineTracer.cpp TextLineTracer.h
	TextLineRefiner.cpp TextLineRefiner.h
	TopBottomEdgeTracer.cpp TopBottomEdgeTracer.h
	CylindricalSurfaceDewarper.cpp CylindricalSurfaceDewarper.h
	DewarpingPointMapper.cpp DewarpingPointMapper.h
	RasterDewarper.cpp RasterDewarper.h
)
SOURCE_GROUP("Sources" FILES ${sources})

ADD_LIBRARY(dewarping STATIC ${sources})

TARGET_LINK_LIBRARIES(dewarping PUBLIC Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Xml)
SET_TARGET_PROPERTIES(dewarping PROPERTIES AUTOMOC ON AUTOUIC ON)
SET_TARGET_PROPERTIES(dewarping PROPERTIES AUTOUIC_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/ui")