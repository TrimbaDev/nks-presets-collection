# Novation BassStation
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - BassStation  2.1
#  - recycle Bitwig Sttudio presets. https://github.com/jhorology/BassStationPack4Bitwig
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
tap      = require 'gulp-tap'
data     = require 'gulp-data'
rename   = require 'gulp-rename'

util     = require '../lib/util'
task     = require '../lib/common-tasks'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'BassStationStereo'
  vendor: 'Novation'
  # magic: 'NvB2'        # BassStation - not work on KK
  magic: 'Nvb2'        # BassStationStreo
  
  #  local settings
  # -------------------------
  # Ableton Live 9.6.2
  abletonInstrumentRackTemplate: 'src/BassStationStereo/templates/BassStationStereo.adg.tpl'


# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task "#{$.prefix}-print-default-meta", ->
  task.print_default_meta $.dir

# print mapping of _Default.nksf
gulp.task "#{$.prefix}-print-default-mapping", ->
  task.print_default_mapping $.dir

# print plugin id of _Default.nksf
gulp.task "#{$.prefix}-print-magic", ->
  task.print_plid $.dir

# generate default mapping file from _Default.nksf
gulp.task "#{$.prefix}-generate-default-mapping", ->
  task.generate_default_mapping $.dir

# extract PCHK chunk from .bwpreset files.
gulp.task "#{$.prefix}-extract-raw-presets", ->
  task.extract_raw_presets_from_bw ["#{$.Bitwig.presets}/#{$.dir}/**/*.bwpreset"], "src/#{$.dir}/presets"

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe tap (file) ->
      basename = path.basename file.path, '.pchk'
      type = switch
        when basename.match /Bass/ then "Bass"
        when basename.match /Lead/ then "Lead"
        else "Other"
      file.contents = new Buffer util.beautify
        vendor: $.vendor
        uuid: util.uuid file
        types: [[type]]
        modes: []
        name: path.basename file.path, '.pchk'
        deviceType: 'INST'
        comment: ''
        bankchain: ['BassStationStereo', 'BassStation Factory', '']
        author: ''
      , on
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task "#{$.prefix}-dist", [
  "#{$.prefix}-dist-image"
  "#{$.prefix}-dist-database"
  "#{$.prefix}-dist-presets"
]

# copy image resources to dist folder
gulp.task "#{$.prefix}-dist-image", ->
  task.dist_image $.dir, $.vendor

# copy database resources to dist folder
gulp.task "#{$.prefix}-dist-database", ->
  task.dist_database $.dir, $.vendor

# build presets file to dist folder
gulp.task "#{$.prefix}-dist-presets", ->
  task.dist_presets $.dir, $.magic

# check
gulp.task "#{$.prefix}-check-dist-presets", ->
  task.check_dist_presets $.dir

#
# deploy
# --------------------------------

gulp.task "#{$.prefix}-deploy", [
  "#{$.prefix}-deploy-resources"
  "#{$.prefix}-deploy-presets"
]

# copy resources to local environment
gulp.task "#{$.prefix}-deploy-resources", [
  "#{$.prefix}-dist-image"
  "#{$.prefix}-dist-database"
], ->
  task.deploy_resources $.dir

# copy database resources to local environment
gulp.task "#{$.prefix}-deploy-presets", [
  "#{$.prefix}-dist-presets"
] , ->
  task.deploy_presets $.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task "#{$.prefix}-release", ["#{$.prefix}-dist"], ->
  task.release $.dir

# export
# --------------------------------

# export from .nksf to .adg ableton drum rack
#
# TODO ableton won't restore plugin state.
gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
  task.export_adg "dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"
  , "#{$.Ableton.racks}/#{$.dir}"
  , $.abletonInstrumentRackTemplate
  , (file, meta) ->
    # edit file path
    dirname = path.dirname file.path
    basename = path.basename file.path
    file.path = path.join dirname, meta.types[0][0], file.relative
