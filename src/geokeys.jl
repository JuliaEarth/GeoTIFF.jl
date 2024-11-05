# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

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

# Corresponding names in the GeoTIFF specification:
# id - KeyID
# tag - TIFFTagLocation
# count - Count
# value - ValueOffset
struct GeoKey
  id::GeoKeyID
  tag::UInt16
  count::UInt16
  value::UInt16
end

# global values
const Undefined = UInt16(0)
const UserDefined = UInt16(32767)

# GTRasterTypeGeoKey values
const PixelIsArea = UInt16(1)
const PixelIsPoint = UInt16(2)

# GTModelTypeGeoKey values
const Projected2D = UInt16(1)
const Geographic2D = UInt16(2)
const Geocentric3D = UInt16(3)
