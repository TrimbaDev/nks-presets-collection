path        = require 'path'
fs          = require 'fs'
_           = require 'underscore'
del         = require 'del'
sqlite3     = require 'sqlite3'
gulp        = require 'gulp'
coffeelint  = require 'gulp-coffeelint'
coffee      = require 'gulp-coffee'
watch       = require 'gulp-watch'
extract     = require 'gulp-riff-extractor'
rewrite     = require 'gulp-nks-rewrite-meta'
changed     = require 'gulp-changed'
data        = require 'gulp-data'
exec        = require 'gulp-exec'
zip         = require 'gulp-zip'
nks         = require 'nks-json'
builder     = require './lib/riff-builder'
beautify    = require 'js-beautify'
uuid        = require 'uuid'

$ =
  #
  # buld environment & misc settings
  #-------------------------------------------
  release: "#{process.env.HOME}/Dropbox/Share/NKS Presets"
  json_indent: 2
  # gulp-exec options
  execOpts:
    continueOnError: false # default = false, true means don't emit error event
    pipeStdout: false      # default = false, true means stdout is written to file.contents
  execReportOpts:
    err: true              # default = true, false means don't write err
    stderr: true           # default = true, false means don't write stderr
    stdout: true           # default = true, false means don't write stdout

  #
  # Native Instruments
  #-------------------------------------------
  NI:
    userContent: "#{process.env.HOME}/Documents/Native Instruments/User Content"
    resources: '/Users/Shared/NI Resources'

  #
  # Ableton Live
  #-------------------------------------------
  Ableton:
    racks: "#{process.env.HOME}/Music/Ableton/User Library/Presets/Instruments/Instrument Rack"

  #
  # Bitwig Studio
  #-------------------------------------------
  Bitwig:
    presets: "#{process.env.HOME}/Documents/Bitwig Studio/Library/Presets"

  #
  # Air Music Technology Velvet
  #-------------------------------------------
  Velvet:
    dir: 'Velvet'
    vendor: 'Air Music Technology'
    PLID:
      "VST.magic": "tvlV"
  #
  # Air Music Technology Xpand!2
  #-------------------------------------------
  Xpand2:
    dir: 'Xpand!2'
    vendor: 'Air Music Technology'
    PLID:
      "VST.magic": "2dpX"

  #
  # Air Music Technology Loom
  #-------------------------------------------
  Loom:
    dir: 'Loom'
    vendor: 'Air Music Technology'
    PLID:
      "VST.magic": "mooL"

  #
  # Air Music Technology Hybrid
  #-------------------------------------------
  Hybrid:
    dir: 'Hybrid'
    vendor: 'Air Music Technology'
    PLID:
      "VST.magic": "drbH"

  #
  # Air Music Technology Vacuum Pro
  #-------------------------------------------
  VacuumPro:
    dir: 'VacuumPro'
    vendor: 'Air Music Technology'
    PLID:
      "VST.magic": "rPcV"

  #
  # Air Music Technology Vacuum Pro
  #-------------------------------------------
  theRiser:
    dir: 'theRiser'
    vendor: 'Air Music Technology'
    PLID:
      "VST.magic": "rsRt"

  #
  # Reveal Sound Spire
  #-------------------------------------------
  Spire:
    dir: 'Spire'
    vendor: 'Reveal Sound'
    PLID:
      "VST.magic": "Spir"

  #
  # Arturia Analog Lab
  #-------------------------------------------
  AnalogLab:
    dir: 'Analog Lab'
    vendor: 'Arturia'
    PLID:
      "VST.magic": "ALab"
    db: '/Library/Arturia/Analog\ Lab/Labo2.db'
    # SQL query for Instruments Sounds
    query_sounds: '''
select
  Sounds.SoundName
  ,Sounds.SoundDesigner
  ,Instruments.InstName
  ,Types.TypeName
  ,Characteristics.CharName
from
  Sounds
  join Instruments on Sounds.InstID = Instruments.InstID
  join Types on Sounds.TypeID = Types.TypeID
  left join SoundCharacteristics on Sounds.SoundGUID = SoundCharacteristics.SoundGUID
  left join Characteristics on SoundCharacteristics.CharID = Characteristics.CharID
where
  Instruments.InstName = $InstName
  and Sounds.SoundName = $SoundName
'''
    # SQL query for Multi Sounds
    query_multis: '''
select
  Multis.MultiName
  ,Multis.MultiDesigner
  ,MusicGenres.MusicGenreName
from
  multis
  join MusicGenres on Multis.MusicGenreID = MusicGenres.MusicGenreID
where
  Multis.MultiName = $MultiName
'''

  #
  # discoDSP Discovery Pro
  #-------------------------------------------
  DiscoveryPro:
    dir: 'DiscoveryPro'
    vendor: 'discoDSP'
    PLID:
      "VST.magic": "DPVx"

  #
  # u-he Hive
  #-------------------------------------------
  Hive:
    dir: 'Hive'
    vendor: 'u-he'
    PLID:
      "VST.magic": "hIVE"

  #
  # Novation BassStation
  #-------------------------------------------
  BassStation:
    dir: 'BassStation'
    vendor: 'Novation'
    PLID:
      "VST.magic": "NvB2"

  #
  # Xfer Records Serum
  #-------------------------------------------
  Serum:
    dir: 'Serum'
    vendor: 'Xfer Records'
    PLID:
      'VST.magic': 'XfsX'
    db: '/Library/Audio/Presets/Xfer\ Records/Serum\ Presets/System/presetdb.dat'
    query: '''
select
  PresetDisplayName
  ,PresetRelativePath
  ,Author
  ,Description
  ,Category
from
  SerumPresetTable
where
  PresetDisplayName = $name
  and PresetRelativePath = $folder
'''

gulp.task 'coffeelint', ->
  gulp.src ['*.coffee', "lib/*.coffee"]
    .pipe coffeelint 'coffeelint.json'
    .pipe coffeelint.reporter()

gulp.task 'coffee', ['coffeelint'], ->
  gulp.src ["lib/*.coffee"]
    .pipe coffee()
    .pipe gulp.dest $.lib

gulp.task 'clean', (cb) ->
  del [
    './**/*~'
     'dist'
     'temp'
    ]
  , force: true, cb


gulp.task 'dist', [
  'velvet-dist'
  'serum-dist'
]

gulp.task 'deploy', [
  'velvet-deploy'
  'serum-deploy'
]

gulp.task 'release', [
  'velvet-release'
  'serum-release'
]

# Air Music Technology Velvet
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Velvet  2.0.6.18983
# ---------------------------------------------------------------


# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'velvet-print-default-meta', ->
  _print_default_meta $.Velvet.dir

# print mapping of _Default.nksf
gulp.task 'velvet-print-default-mapping', ->
  _print_default_mapping $.Velvet.dir

# print plugin id of _Default.nksf
gulp.task 'velvet-print-plid', ->
  _print_plid $.Velvet.dir

# generate default mapping file from _Default.nksf
gulp.task 'velvet-generate-default-mapping', ->
  _generate_default_mapping $.Velvet.dir

# extract PCHK chunk from .nksf files.
gulp.task 'velvet-extract-raw-presets', ->
  _extract_raw_presets [
    "#{$.NI.userContent}/#{$.Velvet.dir}/**/*.nksf"
    "!#{$.NI.userContent}/#{$.Velvet.dir}/_Default.nksf"
    ]
  , "src/#{$.Velvet.dir}/presets"

# generate metadata
gulp.task 'velvet-generate-meta', ->
  presets = "src/#{$.Velvet.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = path.relative presets, path.dirname file.path
      # meta
      meta =
        vendor: $.Velvet.vendor
        uuid: uuid.v4()
        types: [
          ["Piano/Keys"]
          ["Piano/Keys", "Electric Piano"]
        ]
        modes: [folder]
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['Velvet', 'Velvet Factory', '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.Velvet.dir}/presets"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'velvet-dist', [
  'velvet-dist-image'
  'velvet-dist-database'
  'velvet-dist-presets'
]

# copy image resources to dist folder
gulp.task 'velvet-dist-image', ->
  _dist_image $.Velvet.dir, $.Velvet.vendor

# copy database resources to dist folder
gulp.task 'velvet-dist-database', ->
  _dist_database $.Velvet.dir, $.Velvet.vendor

# build presets file to dist folder
gulp.task 'velvet-dist-presets', ->
  _dist_presets $.Velvet.dir, $.Velvet.PLID

# check
gulp.task 'velvet-check-dist-presets', ->
  _check_dist_presets $.Velvet.dir

#
# deploy
# --------------------------------
gulp.task 'velvet-deploy', [
  'velvet-deploy-resources'
  'velvet-deploy-presets'
]

# copy resources to local environment
gulp.task 'velvet-deploy-resources', [
  'velvet-dist-image'
  'velvet-dist-database'
  ], ->
    _deploy_resources $.Velvet.dir

# copy database resources to local environment
gulp.task 'velvet-deploy-presets', [
  'velvet-dist-presets'
  ] , ->
    _deploy_presets $.Velvet.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'velvet-release',['velvet-dist'], ->
  _release $.Velvet.dir

# ---------------------------------------------------------------
# end Air Music Technology Velvet
#


# ---------------------------------------------------------------
# Air Music Technology Xpand!2
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Xpand!2  2.2.4.18852
#  - recycle bitwig presets. https://github.com/jhorology/Xpand2Pack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'xpand2-print-default-meta', ->
  _print_default_meta $.Xpand2.dir

# print mapping of _Default.nksf
gulp.task 'xpand2-print-default-mapping', ->
  _print_default_mapping $.Xpand2.dir

# print plugin id of _Default.nksf
gulp.task 'xpand2-print-plid', ->
  _print_plid $.Xpand2.dir

# generate default mapping file from _Default.nksf
gulp.task 'xpand2-generate-default-mapping', ->
  _generate_default_mapping $.Xpand2.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'xpand2-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.Xpand2.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.Xpand2.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# generate metadata
gulp.task 'xpand2-generate-meta', ->
  presets = "src/#{$.Xpand2.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = path.relative presets, path.dirname file.path
      # meta
      meta =
        vendor: $.Xpand2.vendor
        uuid: uuid.v4()
        types: [
          # remove first 3 char from folder name.
          # ex) '01 Soft Pads' -> 'Soft Pads'
          [folder[3..]]
        ]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['Xpand!2', 'Xpand!2 Factory', '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.Xpand2.dir}/presets"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'xpand2-dist', [
  'xpand2-dist-image'
  'xpand2-dist-database'
  'xpand2-dist-presets'
]

# copy image resources to dist folder
gulp.task 'xpand2-dist-image', ->
  _dist_image $.Xpand2.dir, $.Xpand2.vendor

# copy database resources to dist folder
gulp.task 'xpand2-dist-database', ->
  _dist_database $.Xpand2.dir, $.Xpand2.vendor

# build presets file to dist folder
gulp.task 'xpand2-dist-presets', ->
  _dist_presets $.Xpand2.dir, $.Xpand2.PLID

# check
gulp.task 'xpand2-check-dist-presets', ->
  _check_dist_presets $.Xpand2.dir

#
# deploy
# --------------------------------
gulp.task 'xpand2-deploy', [
  'xpand2-deploy-resources'
  'xpand2-deploy-presets'
]

# copy resources to local environment
gulp.task 'xpand2-deploy-resources', [
  'xpand2-dist-image'
  'xpand2-dist-database'
  ], ->
    _deploy_resources $.Xpand2.dir

# copy database resources to local environment
gulp.task 'xpand2-deploy-presets', [
  'xpand2-dist-presets'
  ] , ->
    _deploy_presets $.Xpand2.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'xpand2-release',['xpand2-dist'], ->
  _release $.Xpand2.dir

# ---------------------------------------------------------------
# end Air Music Technology Xpand!2
#


# ---------------------------------------------------------------
# Air Music Technology Loom
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Loom  1.0.3.18538
#  - recycle bitwig presets. https://github.com/jhorology/LoomPack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'loom-print-default-meta', ->
  _print_default_meta $.Loom.dir

# print mapping of _Default.nksf
gulp.task 'loom-print-default-mapping', ->
  _print_default_mapping $.Loom.dir

# print plugin id of _Default.nksf
gulp.task 'loom-print-plid', ->
  _print_plid $.Loom.dir

# generate default mapping file from _Default.nksf
gulp.task 'loom-generate-default-mapping', ->
  _generate_default_mapping $.Loom.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'loom-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.Loom.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.Loom.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# ---------------------------------------------------------------
# end Air Music Technology Loom
#

# ---------------------------------------------------------------
# Air Music Technology Hybrid
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Hybrid  3.0.0.18468
#  - recycle bitwig presets. https://github.com/jhorology/HybridPack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'hybrid-print-default-meta', ->
  _print_default_meta $.Hybrid.dir

# print mapping of _Default.nksf
gulp.task 'hybrid-print-default-mapping', ->
  _print_default_mapping $.Hybrid.dir

# print plugin id of _Default.nksf
gulp.task 'hybrid-print-plid', ->
  _print_plid $.Hybrid.dir

# generate default mapping file from _Default.nksf
gulp.task 'hybrid-generate-default-mapping', ->
  _generate_default_mapping $.Hybrid.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'hybrid-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.Hybrid.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.Hybrid.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# ---------------------------------------------------------------
# end Air Music Technology Hybrid
#


# ---------------------------------------------------------------
# Air Music Technology VacuumPro
#
# notes
#  - Komplete Kontrol  1.5.0(R3065)
#  - VacuumPro         1.0.3.18538
#  - recycle bitwig presets. https://github.com/jhorology/HybridPack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'vacuumpro-print-default-meta', ->
  _print_default_meta $.VacuumPro.dir

# print mapping of _Default.nksf
gulp.task 'vacuumpro-print-default-mapping', ->
  _print_default_mapping $.VacuumPro.dir

# print plugin id of _Default.nksf
gulp.task 'vacuumpro-print-plid', ->
  _print_plid $.VacuumPro.dir

# generate default mapping file from _Default.nksf
gulp.task 'vacuumpro-generate-default-mapping', ->
  _generate_default_mapping $.VacuumPro.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'vacuumpro-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.VacuumPro.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.VacuumPro.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# ---------------------------------------------------------------
# end Air Music Technology VacuumPro
#


# ---------------------------------------------------------------
# Air Music Technology VacuumPro
#
# notes
#  - Komplete Kontrol  1.5.0(R3065)
#  - theRiser          *unknown
#  - recycle bitwig presets. https://github.com/jhorology/theRiserPack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'theriser-print-default-meta', ->
  _print_default_meta $.theRiser.dir

# print mapping of _Default.nksf
gulp.task 'theriser-print-default-mapping', ->
  _print_default_mapping $.theRiser.dir

# print plugin id of _Default.nksf
gulp.task 'theriser-print-plid', ->
  _print_plid $.theRiser.dir

# generate default mapping file from _Default.nksf
gulp.task 'theriser-generate-default-mapping', ->
  _generate_default_mapping $.theRiser.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'theriser-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.theRiser.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.theRiser.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# ---------------------------------------------------------------
# end Air Music Technology theRiser
#


# ---------------------------------------------------------------
# Reveal Sound Spire
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Spire    (*unknown version)
#  - recycle bitwig presets. https://github.com/jhorology/Xpand2Pack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'spire-print-default-meta', ->
  _print_default_meta $.Spire.dir

# print mapping of _Default.nksf
gulp.task 'spire-print-default-mapping', ->
  _print_default_mapping $.Spire.dir

# print plugin id of _Default.nksf
gulp.task 'spire-print-plid', ->
  _print_plid $.Spire.dir

# generate default mapping file from _Default.nksf
gulp.task 'spire-generate-default-mapping', ->
  _generate_default_mapping $.Spire.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'spire-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.Spire.dir}/Factory Banks/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.Spire.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# ---------------------------------------------------------------
# end Reveal Sound Spire
#


# ---------------------------------------------------------------
# Arturia Analog Lab
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Analog Lab    (*unknown version)
#  - recycle Ableton Live Rack presets. https://github.com/jhorology/AnalogLabPack4Live
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'analoglab-print-default-meta', ->
  _print_default_meta $.AnalogLab.dir

# print mapping of _Default.nksf
gulp.task 'analoglab-print-default-mapping', ->
  _print_default_mapping $.AnalogLab.dir

# print plugin id of _Default.nksf
gulp.task 'analoglab-print-plid', ->
  _print_plid $.AnalogLab.dir

# generate default mapping file from _Default.nksf
gulp.task 'analoglab-generate-default-mapping', ->
  _generate_default_mapping $.AnalogLab.dir

# extract PCHK chunk from ableton .adg files.
gulp.task 'analoglab-extract-raw-presets', ->
  gulp.src ["#{$.Ableton.racks}/#{$.AnalogLab.dir}/**/*.adg"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.AnalogLab.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'echo "now converting file:<%= file.relative %>"'
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/adg2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# generate metadata from serum's sqlite database
gulp.task 'analoglab-generate-meta', ->
  # open database
  db = new sqlite3.Database $.AnalogLab.db, sqlite3.OPEN_READONLY
  gulp.src ["src/#{$.AnalogLab.dir}/presets/**/*.pchk"]
    .pipe data (file, done) ->
      # SQL bind parameters
      soundname = path.basename file.path, '.pchk'
      folder = path.relative "src/#{$.AnalogLab.dir}/presets", path.dirname file.path
      instname = path.dirname folder
      if instname is 'MULTI'
        # multi presets
        params =
          $MultiName: soundname
        db.all $.AnalogLab.query_multis, params, (err, rows) ->
          done err if err
          unless rows and rows.length
            done 'row unfound in multis'
          if rows.length > 1
            done "row duplicated in multis. rows.length:#{rows.length}"
          console.info JSON.stringify rows[0]
          done undefined,
            vendor: $.AnalogLab.vendor
            uuid: uuid.v4()
            types: [['Multi']]
            name: soundname
            modes: [rows[0].MusicGenreName]
            deviceType: 'INST'
            comment: ''
            bankchain: [$.AnalogLab.dir, 'MULTI', '']
            author: rows[0].SoundDesigner?.trim()
      else
        # Instruments presets

        # funny, Arturia change preset name 'Moog' to 'Mogue' in newer version.
        db_soundname = soundname.replace 'Moog', 'Mogue'
        db_soundname = db_soundname.replace 'moog', 'mogue'
        params =
          $InstName: instname
          $SoundName: db_soundname

        # execute query
        db.all $.AnalogLab.query_sounds, params, (err, rows) ->
          done err if err
          unless rows and rows.length
            done 'row unfound in sounds', undefined
          done undefined,
            vendor: $.AnalogLab.vendor
            uuid: uuid.v4()
            types: [[rows[0].TypeName?.trim()]]
            name: soundname
            modes: _.uniq (row.CharName for row in rows)
            deviceType: 'INST'
            comment: ''
            bankchain: [$.AnalogLab.dir, instname, '']
            author: rows[0].SoundDesigner?.trim()

    .pipe data (file) ->
      json = beautify (JSON.stringify file.data), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      file.data
    .pipe gulp.dest "src/#{$.AnalogLab.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()

# ---------------------------------------------------------------
# end Arturia Analog Lab
#


# ---------------------------------------------------------------
# discoDSP Discovery Pro
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Analog Lab    (*unknown version)
#  - recycle Bitwig Sttudio presets. https://github.com/jhorology/DiscoveryProPack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'discoverypro-print-default-meta', ->
  _print_default_meta $.DiscoveryPro.dir

# print mapping of _Default.nksf
gulp.task 'discoverypro-print-default-mapping', ->
  _print_default_mapping $.DiscoveryPro.dir

# print plugin id of _Default.nksf
gulp.task 'discoverypro-print-plid', ->
  _print_plid $.DiscoveryPro.dir

# generate default mapping file from _Default.nksf
gulp.task 'discoverypro-generate-default-mapping', ->
  _generate_default_mapping $.DiscoveryPro.dir

# extract PCHK chunk from bitwig .bwpresetfiles.
gulp.task 'discoverypro-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.DiscoveryPro.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.DiscoveryPro.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# ---------------------------------------------------------------
# end discoDSP Discovery Pro
#


# ---------------------------------------------------------------
# u-he Hive
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Hive   1.0 revision 3514
#  - recycle Bitwig Sttudio presets. https://github.com/jhorology/HivePack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'hive-print-default-meta', ->
  _print_default_meta $.Hive.dir

# print mapping of _Default.nksf
gulp.task 'hive-print-default-mapping', ->
  _print_default_mapping $.Hive.dir

# print plugin id of _Default.nksf
gulp.task 'hive-print-plid', ->
  _print_plid $.Hive.dir

# generate default mapping file from _Default.nksf
gulp.task 'hive-generate-default-mapping', ->
  _generate_default_mapping $.Hive.dir

# extract PCHK chunk from bitwig .bwpresetfiles.
gulp.task 'hive-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.Hive.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.Hive.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# ---------------------------------------------------------------
# end u-he Hive Pro
#


# ---------------------------------------------------------------
# Novation BassStation
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - BassStation  2.1
#  - recycle Bitwig Sttudio presets. https://github.com/jhorology/BassStationPack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'bassstation-print-default-meta', ->
  _print_default_meta $.BassStation.dir

# print mapping of _Default.nksf
gulp.task 'bassstation-print-default-mapping', ->
  _print_default_mapping $.BassStation.dir

# print plugin id of _Default.nksf
gulp.task 'bassstation-print-plid', ->
  _print_plid $.BassStation.dir

# generate default mapping file from _Default.nksf
gulp.task 'bassstation-generate-default-mapping', ->
  _generate_default_mapping $.BassStation.dir

# extract PCHK chunk from bitwig .bwpresetfiles.
gulp.task 'bassstation-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.BassStation.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.BassStation.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# ---------------------------------------------------------------
# end discoDSP Discovery Pro
#


# Xfer Record Serum
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Serum  1.073 Oct 5 2015
# ---------------------------------------------------------------

#
# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'serum-print-default-meta', ->
  _print_default_meta $.Serum.dir

# print mapping of _Default.nksf
gulp.task 'serum-print-default-mapping', ->
  _print_default_mapping $.Serum.dir

# print plugin id of _Default.nksf
gulp.task 'serum-print-plid', ->
  _print_plid $.Serum.dir

# generate default mapping file from _Default.nksf
gulp.task 'serum-generate-default-mapping', ->
  _generate_default_mapping $.Serum.dir

# extract PCHK chunk from .nksf files.
gulp.task 'serum-extract-raw-presets', ->
  _extract_raw_presets [
    "#{$.NI.userContent}/#{$.Serum.dir}/**/*.nksf"
    "!#{$.NI.userContent}/#{$.Serum.dir}/_Default.nksf"
    ]
  , "src/#{$.Serum.dir}/presets"

# generate metadata from serum's sqlite database
gulp.task 'serum-generate-meta', ->
  # open database
  db = new sqlite3.Database $.Serum.db, sqlite3.OPEN_READONLY
  gulp.src ["src/#{$.Serum.dir}/presets/**/*.pchk"]
    .pipe data (file, done) ->
      # SQL bind parameters
      params =
        $name: path.basename file.path, '.pchk'
        $folder: path.relative "src/#{$.Serum.dir}/presets", path.dirname file.path
      # execute query
      db.get $.Serum.query, params, (err, row) ->
        done err,
          vendor: $.Serum.vendor
          uuid: uuid.v4()
          types: [[row.Category?.trim()]]
          name: row.PresetDisplayName?.trim()
          deviceType: 'INST'
          comment: row.Description?.trim()
          bankchain: ['Serum', 'Serum Factory', '']
          author: row.Author?.trim()
    .pipe data (file) ->
      json = beautify (JSON.stringify file.data), indent_size: $.json_indent
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      file.data
    .pipe gulp.dest "src/#{$.Serum.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'serum-dist', [
  'serum-dist-image'
  'serum-dist-database'
  'serum-dist-presets'
]

# copy image resources to dist folder
gulp.task 'serum-dist-image', ->
  _dist_image $.Serum.dir, $.Serum.vendor

# copy database resources to dist folder
gulp.task 'serum-dist-database', ->
  _dist_database $.Serum.dir, $.Serum.vendor

# build presets file to dist folder
gulp.task 'serum-dist-presets', ->
  _dist_presets $.Serum.dir, $.Serum.PLID

# check
gulp.task 'serum-check-dist-presets', ->
  _check_dist_presets $.Serum.dir

#
# deploy
# --------------------------------
gulp.task 'serum-deploy', [
  'serum-deploy-resources'
  'serum-deploy-presets'
]

# copy resources to local environment
gulp.task 'serum-deploy-resources', [
  'serum-dist-image'
  'serum-dist-database'
  ], ->
    _deploy_resources $.Serum.dir

# copy database resources to local environment
gulp.task 'serum-deploy-presets', [
  'serum-dist-presets'
  ] , ->
    _deploy_presets $.Serum.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'serum-release',['serum-dist'], ->
  _release $.Serum.dir

# ---------------------------------------------------------------
# end Xfer Record Serum



# common routines
# ---------------------------------------------------------------

#
# utility
# --------------------------------
# desrilize to json object
_deserialize = (file) ->
  json = nks.deserializer file.contents
    .deserialize()
  beautify (JSON.stringify json), indent_size: $.json_indent

# desrilize to json object
_serialize = (json) ->
  nks.serializer json
    .serialize()
    .buffer()


# read JSON file
# * 'require' can't use for non '.js,.json' file
_require_meta = (filePath) ->
  JSON.parse fs.readFileSync filePath, "utf8"

#
# prepair
# --------------------------------

# generate default parameter mapping file
_generate_default_mapping = (dir) ->
  gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
    .pipe changed "src/#{dir}/mappings",
      hasChanged: (stream, cb, file, dest) ->
        dest = path.join (path.dirname dest), 'default.json'
        changed.compareLastModifiedTime stream, cb, file, dest
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['NICA']
      filename_template: "default.json"
    .pipe data (file) ->
      file.contents = new Buffer _deserialize file
    .pipe gulp.dest "src/#{dir}/mappings"

# print default NISI chunk as JSON
_print_default_meta = (dir) ->
  gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['NISI']
    .pipe data (file) ->
      console.info _deserialize file

# print default NACA chunk as JSON
_print_default_mapping = (dir) ->
  gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['NICA']
    .pipe data (file) ->
      console.info _deserialize file

# print PLID chunk as JSON
_print_plid = (dir) ->
  gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['PLID']
    .pipe data (file) ->
      console.info _deserialize file

# extract PCHK chunk
_extract_raw_presets = (srcs, dest) ->
  gulp.src srcs
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['PCHK']
    .pipe gulp.dest dest

#
# dist
# --------------------------------

# copy image resources to dist folder
_dist_image = (dir, vendor) ->
  gulp.src ["src/#{dir}/resources/image/**/*.{json,meta,png}"]
    .pipe gulp.dest "dist/#{dir}/NI Resources/image/#{vendor.toLowerCase()}/#{dir.toLowerCase()}"

# copy database resources to dist folder
_dist_database = (dir, vendor) ->
  gulp.src ["src/#{dir}/resources/dist_database/**/*.{json,meta,png}"]
    .pipe gulp.dest "dist/#{dir}/NI Resources/dist_database/#{vendor.toLowerCase()}/#{dir.toLowerCase()}"


# build presets file to dist folder
_dist_presets = (dir, PLID) ->
  presets = "src/#{dir}/presets"
  mappings = "./src/#{dir}/mappings"
  dist = "dist/#{dir}/User Content/#{dir}"
  gulp.src ["#{presets}/**/*.pchk"], read: true
    .pipe data (file) ->
      riff = builder 'NIKS'
      # NISI chunk -- metadata
      meta = _serialize _require_meta "#{presets}/#{file.relative[..-5]}meta"
      riff.pushChunk 'NISI', meta
      # NACA chunk -- mapping
      mapping = _serialize require "#{mappings}/default.json"
      riff.pushChunk 'NICA', mapping
      # PLID chunk -- plugin id
      pluginId = _serialize PLID
      riff.pushChunk 'PLID', pluginId
      # PCHK chunk -- raw preset (pluginstates)
      riff.pushChunk 'PCHK', file.contents
      # output file contents
      file.contents = riff.buffer()
      # .pchk -> .nksf
      file.path = "#{file.path[..-5]}nksf"
    .pipe gulp.dest dist

# print all presets
_check_dist_presets = (dir, PLID) ->
  dist = "dist/#{dir}/User Content/#{dir}"
  gulp.src ["#{dist}/**/*.nksf"], read: true
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['NISI', 'NICA', 'PLID']
    .pipe data (file) ->
      console.info _deserialize file
#
# deploy
# --------------------------------

# copy resources to local environment
_deploy_resources = (dir) ->
  gulp.src ["dist/#{dir}/NI Resources/**/*.{json,meta,png}"]
    .pipe gulp.dest $.NI.resources

# copy presets to local environment
_deploy_presets = (dir) ->
  gulp.src ["dist/#{dir}/User Content/**/*.nksf"]
    .pipe gulp.dest $.NI.userContent


#
# release
# --------------------------------

# zip dist file and copy to dropbox.
_release = (dir) ->
  gulp.src ["dist/#{dir}/**/*.{json,meta,png,nksf}"]
    .pipe zip "#{dir}.zip"
    .pipe gulp.dest $.release

