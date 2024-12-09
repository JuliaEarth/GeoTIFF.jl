# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

module GeoTIFF

using TiffImages: AbstractTIFF, DenseTaggedImage, StridedTaggedImage, WidePixel
using ColorTypes: Colorant, Gray
using MappedArrays: mappedarray
using StaticArrays: SVector, SMatrix, SA
using FixedPointNumbers: Fixed, Normed

import TiffImages
import TiffImages: nchannels, channel

include("geokeys.jl")
include("metadata.jl")
include("userutils.jl")
include("image.jl")
include("load.jl")
include("save.jl")

end
