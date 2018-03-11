OneChat.fileUploadMediaWhiteList = function() {
  var mediaTypeWhiteList = OneChat.settings.accepted_media_types

  if (!mediaTypeWhiteList || mediaTypeWhiteList === '*') {
    return;
  }
  return _.map(mediaTypeWhiteList.split(','), function(item) {
    return item.trim();
  });
};

OneChat.fileUploadIsValidContentType = function(type) {
  var list, wildCardGlob, wildcards;
  list = OneChat.fileUploadMediaWhiteList();
  if (!list || _.contains(list, type)) {
    return true;
  } else {
    wildCardGlob = '/*';
    wildcards = _.filter(list, function(item) {
      return item.indexOf(wildCardGlob) > 0;
    });
    if (_.contains(wildcards, type.replace(/(\/.*)$/, wildCardGlob))) {
      return true;
    }
  }
  return false;
};
