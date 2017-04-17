/* Copyright 2014 KDE Connect Indicator Developers
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
namespace KDEConnectIndicator {
    public class DeviceIndicator {
        public string path;
        private Device device;
        private Gtk.Menu menu;
        private AppIndicator.Indicator indicator;
        private Gtk.MenuItem name_item;
        private Gtk.MenuItem battery_item;
        private Gtk.MenuItem status_item;
        private Gtk.MenuItem browse_item;
        private Gtk.MenuItem send_item;
        private Gtk.MenuItem ring_item;
        private Gtk.MenuItem pair_item;
        private Gtk.MenuItem unpair_item;
        private Gtk.MenuItem sms_item;
        private Gtk.SeparatorMenuItem separator;
        private Gtk.SeparatorMenuItem separator2;
        private Gtk.SeparatorMenuItem separator3;
        private string visible_devices = "/tmp/devices";

        public DeviceIndicator (string path) {
            this.path = path;
            device = new Device (path);
            menu = new Gtk.Menu ();

            indicator = new AppIndicator.Indicator (path,
                    				    device.icon_name + "-symbolic",
                                                    AppIndicator.IndicatorCategory.HARDWARE);

            name_item = new Gtk.MenuItem ();
            menu.append (name_item);
            battery_item = new Gtk.MenuItem();
            menu.append (battery_item);
            status_item = new Gtk.MenuItem ();
            menu.append (status_item);
            menu.append (new Gtk.SeparatorMenuItem ());
            browse_item = new Gtk.MenuItem.with_label (_("Browse device"));
            menu.append (browse_item);
            send_item = new Gtk.MenuItem.with_label (_("Send file(s)"));
            menu.append (send_item);
            separator = new Gtk.SeparatorMenuItem ();
            menu.append (separator);
            sms_item = new Gtk.MenuItem.with_label (_("Send SMS"));
            menu.append (sms_item);
            separator2 = new Gtk.SeparatorMenuItem ();
            menu.append (separator2);
            ring_item = new Gtk.MenuItem.with_label (_("Find my phone"));
            menu.append (ring_item);
            separator3 = new Gtk.SeparatorMenuItem ();
            menu.append (separator3);
            pair_item = new Gtk.MenuItem.with_label (_("Request pairing"));
            menu.append (pair_item);
            unpair_item = new Gtk.MenuItem.with_label (_("Unpair"));
            menu.append (unpair_item);

            menu.show_all ();

            update_visibility ();
            update_name_item ();
            update_battery_item ();
            update_status_item ();
            update_pair_item ();

            indicator.set_menu (menu);
            
            name_item.activate.connect (() => {
		var msg = new Gtk.MessageDialog.with_markup (null,
		                                             Gtk.DialogFlags.MODAL,
                			                     Gtk.MessageType.INFO,
                			                     Gtk.ButtonsType.OK,
                			                     "msg");

                msg.set_markup (device.encryption_info);
		msg.run ();
		msg.destroy();
	    });

	    status_item.activate.connect(() => {
		try {
                    Process.spawn_async (null,
                    			 new string[]{"kcmshell5", "kcm_kdeconnect"},
					 null,
					 SpawnFlags.SEARCH_PATH,
					 null,
					 null);
                } catch (Error e) {
                    message (e.message);
                }
	    });

            browse_item.activate.connect (() => {
                device.browse ();
            });

            send_item.activate.connect (() => {
                var chooser = new Gtk.FileChooserDialog (_("Select file(s)"),
                					 null,
                					 Gtk.FileChooserAction.OPEN,
                					 _("Cancel"),
                					 Gtk.ResponseType.CANCEL,
                					 _("Select"),
                					 Gtk.ResponseType.OK);
                
                chooser.select_multiple = true;
                if (chooser.run () == Gtk.ResponseType.OK) {
                    SList<string> urls = chooser.get_uris ();

                    foreach (var url in urls) {
                        device.send_file (url);
                    }
                }
                chooser.close ();
            });
            
            sms_item.activate.connect (() => {
            	var sms_dialog = new SMSCompose (this.device);
            	sms_dialog.show ();
            });

            ring_item.activate.connect (() => {
		device.find_my_phone ();
	    });
			
            pair_item.activate.connect (() => {
                device.request_pair ();
            });
            
            unpair_item.activate.connect (() => {
                device.unpair ();
            });

            device.charge_changed.connect ((charge) => {
                update_battery_item ();
            });
            
            device.state_changed.connect ((charge) => {
                update_battery_item ();
            });
            
            device.pairing_error.connect (()=>{
                update_pair_item ();
                update_status_item ();
            });
            
            device.plugins_changed.connect (()=>{
                update_battery_item ();
                update_pair_item ();
            });
            
            device.reachable_status_changed.connect (()=>{
                update_visibility ();
                update_pair_item ();
                update_status_item ();
                update_icon_item ();
            });
            
            device.trusted_changed.connect ((trusted)=>{
                if (!trusted)
                    update_visibility ();

                update_pair_item ();
                update_status_item ();
                update_battery_item ();
                update_icon_item ();
            });
        }
        
        public void device_visibility_changed (bool visible) {
            message ("%s visibilitiy changed to %s", device.name, visible?"true":"false");
            update_visibility ();
            update_name_item ();
            update_battery_item ();
            update_status_item ();
            update_pair_item ();
            update_icon_item ();
        }

        private void update_visibility () {
            if (!device.is_reachable)
                indicator.set_status (AppIndicator.IndicatorStatus.PASSIVE);
            else
                indicator.set_status (AppIndicator.IndicatorStatus.ACTIVE);
        }
        
        private void update_name_item () {
            name_item.label = device.name;
        }

        private void update_icon_item(){
	    indicator.set_icon_full (device.icon_name + "-symbolic", "");
	}
        
        private void update_battery_item () {
            battery_item.visible = device.is_trusted
                && device.is_reachable
                && device.has_plugin ("kdeconnect_battery");
            battery_item.label = _("Battery : ") + "%d%%".printf(device.battery);
            if (device.is_charging ())
                battery_item.label += _(" (charging)");
        }
        
        private void update_status_item () {

            if (device.is_reachable) {
                if (device.is_trusted) {
                    status_item.label = _("Device Reachable and Trusted");
                    write_status ();
                }
                else {
                    status_item.label = _("Device Reachable but Not Trusted");
                    delete_status ();
                }
            } else {
                if (device.is_trusted) {
                    status_item.label = _("Device Trusted but not Reachable");
                    delete_status ();
                }
                else {
	            status_item.label = _("Device Not Reachable and Not Trusted");
                    delete_status ();
		    // is this even posible?
                }
            }
        }
        
        private void update_pair_item () {
            var trusted = device.is_trusted;
            var reachable = device.is_reachable;
            
            pair_item.visible = !trusted;
            unpair_item.visible = trusted;

            browse_item.visible = trusted && device.has_plugin ("kdeconnect_sftp");
            browse_item.sensitive = reachable;

            send_item.visible = trusted && device.has_plugin ("kdeconnect_share");
            send_item.sensitive = reachable;

            sms_item.visible = trusted && device.has_plugin("kdeconnect_telephony");
            sms_item.sensitive = reachable;

            ring_item.visible = trusted && device.has_plugin ("kdeconnect_findmyphone");
            ring_item.sensitive = reachable;
            
            separator.visible = browse_item.visible || send_item.visible;
            separator2.visible = sms_item.visible;
            separator3.visible = ring_item.visible;
        }

        private int write_status () {
	    var file = File.new_for_path (visible_devices);

            if (!file.query_exists ()) {
        	message ("File '%s' doesn't exist.\n", file.get_path ());
        	return 1;
    	    }
    	    else{
    	    	message ("File path exist '%s'\n", file.get_path());
    	    }

    	    StringBuilder sb = new StringBuilder();

    	    string device_path = "/modules/kdeconnect/devices/";
            string device_id = this.path.replace(device_path, "");
            string name_id = "- "+device.name+" : "+device_id;

    	    try {
        	var dis = new DataInputStream (file.read ());

        	string line;

		//If the file contains one reference to this device just igone
        	while ((line = dis.read_line (null)) != null) {
            	      message ("Status found on file %s\n", line);
            	      if (name_id != line)
            	      	sb.append (line+"\n");
            	      else
            	        return 1;
        	}

		//If the file don't have any reference to this write it
        	sb.append (name_id+"\n");

    	    } catch (Error e) {
       		error ("%s", e.message);
    	    }

    	    try {
                if (file.query_exists ()) {
                   file.delete ();
                }

                var dos = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));

                uint8[] data = sb.str.data;
                long written = 0;
                while (written < data.length) {
                   written += dos.write (data[written:data.length]);
                }
            } catch (Error e) {
        	message ("%s\n", e.message);
        	return 1;
    	    }

	    return 0;
        }

        private int delete_status () {
	    var file = File.new_for_path (visible_devices);

            if (!file.query_exists ())
        	message ("File '%s' doesn't exist.\n", file.get_path ());
    	    else
    	    	message ("File path exist '%s'\n", file.get_path());

    	    StringBuilder sb = new StringBuilder();

    	    string device_path = "/modules/kdeconnect/devices/";
            string device_id = this.path.replace(device_path, "");
            string name_id = "- "+device.name+" : "+device_id;

    	    try {
        	var dis = new DataInputStream (file.read ());

        	string line;

        	while ((line = dis.read_line (null)) != null) {
            	      message ("Delete status found on file %s\n", line);
            	      if (line != name_id)
		      	sb.append (line+"\n");
        	}

    	    } catch (Error e) {
       		error ("%s", e.message);
    	    }

    	    try {
                if (file.query_exists ()) {
                   file.delete ();
                }

                var dos = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));

                uint8[] data = sb.str.data;
                long written = 0;
                while (written < data.length) {
                   written += dos.write (data[written:data.length]);
                }
            } catch (Error e) {
        	message ("%s\n", e.message);
    	    }

	    return 0;
        }
    }
}
