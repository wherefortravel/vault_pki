# load vault gem from wherefor-pki/files/default/vendor/gems
# https://www.sethvargo.com/using-gems-with-chef/
$LOAD_PATH.push *Dir[File.expand_path('../../files/default/vendor/gems/**/lib', __FILE__)]
$LOAD_PATH.unshift *Dir[File.expand_path('..', __FILE__)]
