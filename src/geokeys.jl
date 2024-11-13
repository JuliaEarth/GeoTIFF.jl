# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

"""
    GeoTIFF.GeoKeyID

Enum of all GeoKey IDs supported by GeoTIFF.

See [Requirements Class GeoKeyDirectoryTag](https://docs.ogc.org/is/19-008r4/19-008r4.html#_requirements_class_geokeydirectorytag)
section of the GeoTIFF specification for more details.
"""
@enum GeoKeyID::UInt16 begin
  GTRasterTypeGeoKey = 1025
  GTModelTypeGeoKey = 1024
  ProjectedCRSGeoKey = 3072
  GeodeticCRSGeoKey = 2048
  VerticalGeoKey = 4096
  GTCitationGeoKey = 1026
  GeodeticCitationGeoKey = 2049
  ProjectedCitationGeoKey = 3073
  VerticalCitationGeoKey = 4097
  GeogAngularUnitsGeoKey = 2054
  GeogAzimuthUnitsGeoKey = 2060
  GeogLinearUnitsGeoKey = 2052
  ProjLinearUnitsGeoKey = 3076
  VerticalUnitsGeoKey = 4099
  GeogAngularUnitSizeGeoKey = 2055
  GeogLinearUnitSizeGeoKey = 2053
  ProjLinearUnitSizeGeoKey = 3077
  GeodeticDatumGeoKey = 2050
  PrimeMeridianGeoKey = 2051
  PrimeMeridianLongitudeGeoKey = 2061
  EllipsoidGeoKey = 2056
  EllipsoidSemiMajorAxisGeoKey = 2057
  EllipsoidSemiMinorAxisGeoKey = 2058
  EllipsoidInvFlatteningGeoKey = 2059
  VerticalDatumGeoKey = 4098
  ProjectionGeoKey = 3074
  ProjMethodGeoKey = 3075
  ProjStdParallel1GeoKey = 3078
  ProjStdParallel2GeoKey = 3079
  ProjNatOriginLongGeoKey = 3080
  ProjNatOriginLatGeoKey = 3081
  ProjFalseOriginLongGeoKey = 3084
  ProjFalseOriginLatGeoKey = 3085
  ProjCenterLongGeoKey = 3088
  ProjCenterLatGeoKey = 3089
  ProjStraightVertPoleLongGeoKey = 3095
  ProjAzimuthAngleGeoKey = 3094
  ProjFalseEastingGeoKey = 3082
  ProjFalseNorthingGeoKey = 3083
  ProjFalseOriginEastingGeoKey = 3086
  ProjFalseOriginNorthingGeoKey = 3087
  ProjCenterEastingGeoKey = 3090
  ProjCenterNorthingGeoKey = 3091
  ProjScaleAtNatOriginGeoKey = 3092
  ProjScaleAtCenterGeoKey = 3093
end

"""
    GeoTIFF.GeoKey(id, tag, count, value)

GeoKey Entry that is stored in [`GeoKeyDirectory`](@ref).

Corresponding field names in the GeoTIFF specification:
* `id`: KeyID
* `tag`: TIFFTagLocation
* `count`: Count
* `value`: ValueOffset

See [Requirements Class GeoKeyDirectoryTag](https://docs.ogc.org/is/19-008r4/19-008r4.html#_requirements_class_geokeydirectorytag)
section of the GeoTIFF specification for a explanation of each field.
"""
struct GeoKey
  id::GeoKeyID
  tag::UInt16
  count::UInt16
  value::UInt16
end

# generic values

"""
    GeoTIFF.Undefined

GeoKey value that indicate intentionally omitted parameters.
"""
const Undefined = UInt16(0)

"""
    GeoTIFF.UserDefined

GeoKey value that indicate user defined parameters.
"""
const UserDefined = UInt16(32767)

# GTRasterTypeGeoKey values

"""
    GeoTIFF.PixelIsArea

PixelIsArea raster type, i.e each pixel of the image is a grid element.
"""
const PixelIsArea = UInt16(1)

"""
    GeoTIFF.PixelIsPoint

PixelIsPoint raster type, i.e each pixel of the image is a grid vertex.
"""
const PixelIsPoint = UInt16(2)

# GTModelTypeGeoKey values

"""
    GeoTIFF.Projected2D

Projected CRS model type.
"""
const Projected2D = UInt16(1)

"""
    GeoTIFF.Geographic2D

Geographic 2D CRS model type.
"""
const Geographic2D = UInt16(2)

"""
    GeoTIFF.Geocentric3D

Geocentric 3D CRS model type.
"""
const Geocentric3D = UInt16(3)
