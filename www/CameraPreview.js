
var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');

var PLUGIN_NAME = "CameraPreview";

var CameraPreview = function() {
};

CameraPreview.setOnPictureTakenHandler = function(onPictureTaken) {
  exec(onPictureTaken, onPictureTaken, PLUGIN_NAME, "setOnPictureTakenHandler", []);
};

CameraPreview.setOnLogHandler = function(onLog) {
  exec(onLog, onLog, PLUGIN_NAME, "wLog", []);
};

//@param rect {x: 0, y: 0, width: 100, height:100}
//@param defaultCamera "front" | "back"
CameraPreview.startCamera = function(rect, defaultCamera, tapEnabled, dragEnabled, toBack, alpha, successCallback, errorCallback) {
  if (typeof(alpha) === 'undefined') alpha = 1;
  exec(successCallback, errorCallback, PLUGIN_NAME, "startCamera", [rect.x, rect.y, rect.width, rect.height, defaultCamera, !!tapEnabled, !!dragEnabled, !!toBack, alpha]);
};
CameraPreview.stopCamera = function() {
  exec(null, null, PLUGIN_NAME, "stopCamera", []);
};
//@param size {maxWidth: 100, maxHeight:100}
CameraPreview.takePicture = function(size) {
  var params = [0, 0];
  if(size){
    params = [size.maxWidth, size.maxHeight];
  }
  exec(null, null, PLUGIN_NAME, "takePicture", params);
};

CameraPreview.setColorEffect = function(effect) {
  exec(null, null, PLUGIN_NAME, "setColorEffect", [effect]);
};

CameraPreview.setBlurEffect = function(value) {
  exec(null, null, PLUGIN_NAME, "setBlurEffect", [value]);
};

CameraPreview.switchCamera = function(callback) {
  exec(callback, callback, PLUGIN_NAME, "switchCamera", []);
};

CameraPreview.hide = function() {
  exec(null, null, PLUGIN_NAME, "hideCamera", []);
};

CameraPreview.show = function() {
  exec(null, null, PLUGIN_NAME, "showCamera", []);
};

CameraPreview.disable = function(disable) {
  exec(null, null, PLUGIN_NAME, "disable", [disable]);
};

CameraPreview.getSupportedPreviewSizes = function (callback) {
  exec(callback, callback, PLUGIN_NAME, "getSupportedPreviewSizes", []);
};

CameraPreview.getSupportedPictureSizes = function (callback) {
  exec(callback, callback, PLUGIN_NAME, "getSupportedPictureSizes", []);
};

CameraPreview.getCameraFOV = function (successCallback, errorCallback) {
  exec(successCallback, errorCallback, PLUGIN_NAME, "getCameraFOV", []);
};

module.exports = CameraPreview;
