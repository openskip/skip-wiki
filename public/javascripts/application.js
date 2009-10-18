// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

(function() {
  jQuery.fn.toggleTwoPain = function() {
    this.siblings(".page-header").toggleClass("two_pain").end().
    siblings(".page-content").toggleClass("two_pain").end().
    siblings(".page-attachments").toggleClass("two_pain");
  }

  jQuery.fn.preview = function(config){
    var root = this;
    var textarea = (config["texrtarea"]) ? jQuery(config["textarea"]) : root.siblings("textarea");

    function showPreview(){
      if(config["editor"]){
        var data = { "page[content_hiki]" : config["editor"].getData(),
                     "authenticity_token":root.parents("form").find("input[name=authenticity_token]").val() }
      }else{
        var data = root.parents("form").serializeArray();
        data = jQuery.grep(data, function(o){return o.name != "_method"});
      }

      try{
        root.find("div.rendered").load(config["url"], data, function(){
            textarea.hide();
            root.
              find("div.rendered").fadeIn("fast").end().
              find("ul li.show").hide().end().
              find("ul li.hide").fadeIn("fast");
        });
      }catch(e){ console.log(e) };
      return false;
    }

    function hidePreview(){
      textarea.fadeIn("fast");
      root.
        find("div.rendered").hide().end().
        find("ul li.hide").hide().end().
        find("ul li.show").fadeIn("fast");
      return false;
    };

    root.find("li.show a.operation").click(showPreview);
    root.find("li.hide a.operation").click(hidePreview).trigger("click");
  };

  jQuery.fn.toggleEditor = function(rich, hiki, config){
    var label = jQuery(config["label"]);
    var hiki_content = jQuery(hiki);
    var html_content = jQuery(rich);

    function toggle(){
      if(jQuery(this).val() == "hiki"){
        label.attr("for", hiki_content.find("textarea").attr("id"));
        hiki_content.show(); html_content.hide();
      }else{
        label.attr("for", html_content.find("textarea").attr("id"));
        hiki_content.hide(); html_content.show();
      }
    }

    jQuery(this).change(toggle).filter(":checked").trigger("change");
  };

  jQuery.fn.skipEditor = function(config){
    var root = this;
    var form = root.parents("form");
    function HikiEditor(){ this.initialize.apply(this, arguments); };
    HikiEditor.prototype = {
      initialize : function(textarea, preview){
        this.textarea = jQuery(textarea);
        this.originalContent = this.textarea.val();

        this.enablePreview(preview);
      },
      setData : function(content){
        this.originalContent = content;
        this.textarea.val(content);
        // FIXME Observerに通知する方法
        jQuery(".page form").find("input[type=submit]").disable().end().find("span.notice").hide();
      },
      getData : function(ignore){ return this.textarea.val(); },
      needToSave : function(){ return this.getData() != this.originalContent },
      insert : function(elem){
        var ins  = (elem.get(0).tagName == "IMG") ? "{{image('"+ elem.attr('src') +"')}}"
                                                  : "[[" + elem.text() + "|" + elem.attr("href") + "]]";
        var text = this.textarea.val();
        if(this.textarea.get(0).selectionStart){ // Firefox
          var pos  = this.textarea.get(0).selectionStart;
          this.textarea.val(text.substr(0, pos) + ins + text.substr(pos, text.length));
        }else{
          this.textarea.val(text + ins);
        }
      },
      enablePreview : function(config){
        this.textarea.siblings(config["selector"]).preview({"url":config["url"], "editor": this });
      },
      beginObserver : function(editor){
        this.textarea.delayedObserver(0.5, function(){
          if(editor.needToSave()){
            jQuery(".page form").find("input[type=submit]").enable().end().find("span.notice").show();
          }else{
            jQuery(".page form").find("input[type=submit]").disable().end().find("span.notice").hide();
          }
        });
      }
    };

    function RichEditor(){ this.initialize.apply(this, arguments); };
    RichEditor.prototype = {
      initialize : function(editorName, basePath, height){
        var options = {
          'customConfig': basePath,
          'toolbar': 'Entry',
        };

        var ckeditor = CKEDITOR.replace(editorName, options);
        var flag = true

        ckeditor.on('selectionChange', function (editorInstance){
          if(editorInstance.editor.checkDirty() && flag){
            jQuery(".page form").find("input[type=submit]").enable().end().find("span.notice").show();
          }else if(editorInstance.editor.checkDirty()){
            flag = true;
          }else{
            jQuery(".page form").find("input[type=submit]").disable().end().find("span.notice").hide();
          }
        });
        ckeditor.on('reset', function (editorInstance){
          jQuery(".page form").find("input[type=submit]").disable().end().find("span.notice").hide();
        });

        this.api = function(){ return ckeditor };
        this.flag = function(){ return flag };
        this.setFlag = function(boolean){ flag = boolean };
      },
      setData : function(content){
        jQuery(".page form").find("input[type=submit]").disable().end().find("span.notice").hide();
        this.setFlag(false);
        this.api().setData(content, true) },
      getData : function(force){ return this.api().getData(force) },
      needToSave: function(){ return this.api().checkDirty() && (jQuery.trim( this.api().getData() ).length > 0) && this.flag(); },
      insert : function(elem){ this.api().insertHtml(elem.wrap('<span></span>').parent().html()); }
    }

    function SwitchableEditor(){ this.initialize.apply(this, arguments) };
    SwitchableEditor.prototype = {
      initialize : function(currentFormatType, richEditorOpt, hikiEditorOpt, config){
        this.richEditorOpt = richEditorOpt;
        this.hikiEditorOpt = hikiEditorOpt;
        this.submit_to_save = config["submit_to_save"];
        if(!jQuery.isFunction(currentFormatType)){
          this.currentFormatType = function(){ return currentFormatType };
        }else{
          this.currentFormatType = currentFormatType;
        }
      },

      setData : function(content){ return this.editor().setData(content) },
      getData : function(force){ return this.editor().getData(force) },
      needToSave: function(){ return this.editor().needToSave() },
      insert : function(elem){ this.editor().insert(elem) },

      editor : function(){
        if(this.currentFormatType() == "hiki"){
          if(!this.hikiEditor){
            this.hikiEditor = new HikiEditor(this.hikiEditorOpt["selector"], this.hikiEditorOpt["preview"]);
            if(!this.submit_to_save){
              this.hikiEditor.beginObserver(this.hikiEditor);
            }
          }
          return this.hikiEditor;
        }else{
          if(!this.richEditor){
            this.richEditor = new RichEditor(this.richEditorOpt["name"], this.richEditorOpt["basePath"], this.richEditorOpt["height"]);
          }
          return this.richEditor;
        }
      }
    };

    function addDynamicSave(){
      form.one("submit", createHistory).
           find("input[type=submit]").disable().end().
           find("a.back").click(confirmBack);
    };

    function confirmBack(){
      if(editorApi.needToSave()){
        return confirm("未保存の更新があります。移動しますか?");
      }else{
        return true;
      }
    };

    function createHistory(){
      var button = jQuery(this);
      return saveHistory("POST", function(req,_){
        form.attr("action", req.getResponseHeader("Location"));
        button.submit( updateHistory );
      });
    };

    function updateHistory(){
      return saveHistory("PUT", function(){});
    }

    function saveHistory(method, onSuccess){
      if(!editorApi.needToSave()){
        alert("No need to save");
        return false;
      }
      var content = editorApi.getData(true);

      jQuery.ajax({ type: method,
                    url:  form.attr("action") + ".js",
                    data: ({"authenticity_token": $("input[name=authenticity_token]").val(),
                            "history[content]"  : content }),
                    complete : function(req, stat){
                      if(stat == "success"){
                        editorApi.setData(content);
                        onSuccess(req, stat);
                      }
                    } });
      return false;
    }

    var editorApi = new SwitchableEditor(config["currentFormatType"], config["richEditor"], config["hikiEditor"], config);
    editorApi.editor(); // boot with initial state;

    if(config["submit_to_save"]){
      jQuery("input[type=radio][name='page[format_type]']").change(function(){ editorApi.editor() });
    } else {
          addDynamicSave();
    };

    jQuery(config["linkPalette"]["selector"] || "#linkPalette").linkPalette(
      jQuery.extend({}, config["linkPalette"], {"callback":function(elem){ editorApi.insert(elem) }})
    );
    return jQuery(this);
  };

  jQuery.fn.reloadLabelSelect = function(config){
    var select = jQuery(this).find("select");
    var proto = $('<option></option>');
    jQuery.getJSON(config["url"], function(data, status){
      if(status != "success"){ return ; }
      select.empty();
      jQuery.each(data, function(num, l){
        var label = l["label_index"];
        var option = proto.clone();
        option.attr("value", label.id).text(label.display_name);
        select.append(option);
      });
    });
  };

  jQuery.fn.manageNote = function(config){
    var table = jQuery(this).find("table");

    function update(td, _req, _stat){
      var name = td.find("[name='note[description]']").val();
      td.find("span.note_description").text(name);
      return false;
    }

    jQuery.each(table.find("td.inplace-edit"), function(){jQuery(this).aresInplaceEditor({callback:update}); });
  };

  jQuery.fn.manageLabel = function(config){
    var table = jQuery(this).find("table");

    function showValidationError(xhr){
      var errors = jQuery.httpData( xhr, "json");
      var ul = jQuery("div.new ul.errors");
      if( (ul.length == 0) ){
        ul = jQuery("<ul class='errors'>");
        ul.appendTo( jQuery("div.new") );
      }
      ul.empty();

      jQuery.each(errors, function(){ jQuery("<li>").text(this.toString()).appendTo(ul) });
    }

    function update(td, _req, _stat){
      var name  = td.find("[name='label_index[display_name]']").val();

      td.find("span.label_badge").text(name);
      return false;
    }

    jQuery.each(table.find("td.inplace-edit"), function(){jQuery(this).aresInplaceEditor({callback:update}) });
  };

  jQuery.fn.aresInplaceEditor = function(config){
    var self = jQuery(this);
    var form = self.find("div.edit form");
    var messages = jQuery.extend({
                     sending: "Sending..."
                   },config["messages"])

    function showIPE(){
      self.find("div.edit").show().siblings("div.show").hide();
    }

    function hideIPE(){
      self.find("div.show").show().siblings("div.edit").hide();
    }

    function submitIPE(){
      try{
        var submitLabel = form.find("input[type=submit]").val();
        jQuery.ajax({url: form.attr("action") + ".js",
          type: "PUT",
          data: form.serializeArray(),
          dataType: "json",
          beforeSend: function(){
            self.find(".indicator").show();
            self.find("span.ipe-cancel").hide();
            if(messages["sending"]){ form.find("input[type=submit]").val( messages["sending"]) };
          },
          complete: function(req, status){
            self.find(".indicator").hide();
            self.find("span.ipe-cancel").show();
            if(messages["sending"]){ form.find("input[type=submit]").val( submitLabel ) };
            hideIPE();
            return config["callback"](self, req, status);
          }
        });
      }catch(e){
        alert(e);
      }
      return false;
    }

    self.
      find("div.show").
        find(".ipe-trigger").click(showIPE).end().end().
      find("div.edit").
        find("form").submit(submitIPE).
          find(".ipe-cancel").click(hideIPE).end().end();

    return self;
  };
})(jQuery);

application = function(){}
application.headOK = function(xhr) {
  return xhr.responseText.match(/\s*/) &&
         xhr.status >= 200 &&
         xhr.status <  300
}

application.post = function(form, parameters) {
  var paramFromForm = {
    url  : form.attr("action") + ".js",
    type : "POST",
    data : form.serializeArray()
  }
  jQuery.ajax(jQuery.extend(paramFromForm, parameters));
}

application.callbacks = {
  pageDisplaynameEditor : function(root, req, stat){
    var location = req.getResponseHeader("location");

    if(stat == "success"){
      var data = jQuery.httpData( req, "json")["page"];
      root.find("span.title").html(
        "<a href='" + location + "'>" +  data["display_name"] + "</a>").effect("highlight", {}, 2*1000);
      root.find("form input[type=text]").val(data["display_name"]);
    } else if(stat == "parsererror" && req.responseText.match(/\s*/)){
      root.find("span.title").html(
        "<a href='" + location + "'>" + root.find("form input[type=text]").val() + "</a>"
      ).effect("highlight", {}, 2*1000);
    } else if(stat == "error" && req.status == "422"){
      alert(req.responseText);
    }
  },

  wikiDisplaynameEditor : function(root, req, stat){
    var location = req.getResponseHeader("location");

    if(stat == "success"){
      var data = jQuery.httpData( req, "json")["wiki"];
      root.find("span.note_title").html(
        "<a href='" + location + "'>" +  data["display_name"] + "</a>").effect("highlight", {}, 2*1000);
      root.find("form input[type=text]").val(data["display_name"]);
    } else if(stat == "parsererror" && req.responseText.match(/\s*/)){
      root.find("span.note_title").html(
        "<a href='" + location + "'>" + root.find("form input[type=text]").val() + "</a>"
      ).effect("highlight", {}, 2*1000);
    } else if(stat == "error" && req.status == "422"){
      alert(req.responseText);
    }
  },

  refreshAttachments : function(errorMessage){
    return function(){
      var iframe = jQuery(this.contentWindow.document);
      var url = iframe.get(0).location.href;
      jQuery.getJSON(url, null, function(data, status){
        var tbody = jQuery("div.attachments table tbody");
        var error = jQuery("#error-explanation").empty();

        if(tbody.find("tr:not(.attachment-row-prototype)").length == data.length){
          error.append(iframe.find("body #error-explanation ul").clone());
          jQuery("#flash_message").trigger("error", errorMessage);
          return false;
        }
        var tr = tbody.find("tr:nth-child(1)").clone();
        tbody.empty();
        var row = null;
        jQuery.each(data, function(num, json){
          var atmt = json["attachment"];
          row = tr.clone().removeClass("attachment-row-prototype");
          row.find("td.content_type").text(atmt["content_type"]).end().
              find("td.display_name").text(atmt["display_name"]).end().
              find("td.size").text(atmt["size"]).end().
              find("td.updated_at").text(atmt["updated_at"]).end().
              find("td.operation a").attr("href", atmt["path"]).end().
          appendTo(tbody);
        });
        tbody.find("tr:first-child").effect("highlight", {}, 2*1000);
      });
    }
  }
};

