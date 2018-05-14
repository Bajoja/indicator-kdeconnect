/* Copyright 2014 KDE Connect Indicator Developers
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

using Utils;

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
        private Gtk.MenuItem browse_items;
        private Gtk.Menu browse_items_submenu;        
        private Gtk.MenuItem send_item;
        private Gtk.MenuItem send_url;
        private Gtk.MenuItem ring_item;
        private Gtk.MenuItem pair_item;
        private Gtk.MenuItem unpair_item;
        private Gtk.MenuItem sms_item;
        private Gtk.SeparatorMenuItem separator;
        private Gtk.SeparatorMenuItem separator2;
        private Gtk.SeparatorMenuItem separator3;        
        private Gtk.SeparatorMenuItem separator4;

        public DeviceIndicator (string path) {
            this.path = path;
            device = new Device (path);
            menu = new Gtk.Menu ();

            indicator = new AppIndicator.Indicator (path,
                    				                device.icon,
                                                    AppIndicator.IndicatorCategory.HARDWARE);
                                                    
            name_item = new Gtk.MenuItem ();
            menu.append (name_item);

            name_item.activate.connect (() => {
                try {
	    	        Process.spawn_async (null,
	    	     	                 	 new string[]{"indicator-kdeconnect-settings"},
	    	     			             null,
	    	     			             SpawnFlags.SEARCH_PATH,
	    	     			             null,
	    	     			             null);
	    	    } catch (Error	e) {
	    	        message (e.message);
	    	    }
	        });

            battery_item = new Gtk.MenuItem();
            menu.append (battery_item);
            
            //  battery_item.activate.connect (() => {
	    	    
	        //  });
            
            status_item = new Gtk.MenuItem ();
            menu.append (status_item);
            
            status_item.activate.connect (() => {
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
            
            separator4 = new Gtk.SeparatorMenuItem ();
            menu.append (separator4);

            browse_item = new Gtk.MenuItem.with_label (_("Browse device"));                                      
            menu.append (browse_item);  
            
            browse_item.activate.connect (() => {                                        
                device.browse ();
            });

            browse_items = new Gtk.MenuItem.with_label (_("Browse device"));  
            menu.append (browse_items);
            browse_items_submenu = new Gtk.Menu(); 
                                      
            browse_items.set_submenu (browse_items_submenu);
            
            //TODO: Check why is not working on menu items for browse

            
            send_item = new Gtk.MenuItem.with_label (_("Send file(s)"));
            menu.append (send_item);

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

		            urls.@foreach ((item) => {
		    	        device.send_file(item);
		            });
                }
                
                chooser.close ();
            });

            if(device.show_send_url) {
                send_url = new  Gtk.MenuItem.with_label (_("Send URL"));

                menu.append (send_url);

                send_url.activate.connect (() => {
                    var send_url_dialog = new Utils.SendURL(this.device.send_file);
                    send_url_dialog.show ();
                });
            }            
                                
            separator = new Gtk.SeparatorMenuItem ();
            menu.append (separator);
            
            
            sms_item = new Gtk.MenuItem.with_label (_("Send SMS"));
            menu.append (sms_item);

            sms_item.activate.connect (() => {
            	try{
		            Process.spawn_async (null,
		    		                     new string[]{"/usr/share/indicator-kdeconnect/Sms.py",
					                                  "-d",
					                                  device.id},
				                         null,
				                         SpawnFlags.SEARCH_PATH,
				                         null,
				                         null);
	    	    } catch (Error e) {
		            message (e.message);
            	}
            });

            
            separator2 = new Gtk.SeparatorMenuItem ();
            menu.append (separator2);
            
            ring_item = new Gtk.MenuItem.with_label (_("Find my phone"));
            menu.append (ring_item);

            ring_item.activate.connect (() => {
		        device.find_my_phone ();
	        });
            
            separator3 = new Gtk.SeparatorMenuItem ();
            menu.append (separator3);
            
            pair_item = new Gtk.MenuItem.with_label (_("Request pairing"));
            menu.append (pair_item);

            pair_item.activate.connect (() => {
                device.request_pair ();
            });
            
            unpair_item = new Gtk.MenuItem.with_label (_("Unpair"));
            menu.append (unpair_item);            
            
            unpair_item.activate.connect (() => {
                device.unpair ();
            });	        

            //---------------------------------------------------------------//

            device.charge_changed.connect ((charge) => {
                update_battery_item ();
            });
            
            device.state_changed.connect ((charge) => {
                update_battery_item ();
            });
            
            device.pairing_error.connect (() => {
                update_pair_item ();
                update_status_item ();
            });
            
            device.plugins_changed.connect (() => {
                update_battery_item ();
                update_pair_item ();
            });
            
            device.reachable_status_changed.connect (() => {
                update_visibility ();
                update_pair_item ();
                update_status_item ();
                update_icon_item ();
            });
            
            device.trusted_changed.connect ((trusted) => {
                if (!trusted)
                    update_visibility ();

                update_pair_item ();
                update_status_item ();
                update_battery_item ();
                update_icon_item ();
            });           

            device.mounted.connect ( () => {
                update_browse_items();
            });   
            
            device.unmounted.connect ( () => {
                update_browse_items();
            });   

            update_browse_items();
            update_visibility ();
            update_name_item ();
            update_battery_item ();
            update_status_item ();
            update_pair_item ();

            menu.show_all ();

            indicator.set_menu (menu);
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

        private void update_icon_item() {
	        indicator.set_icon_full (device.icon, "");
	    }
        
        private void update_battery_item () {
            battery_item.visible = device.is_trusted && 
                                   device.is_reachable && 
                                   device.has_plugin ("kdeconnect_battery");

            battery_item.label = _("Battery : ") + "%d%%".printf(device.battery);
            
            if (device.is_charging ())
                battery_item.label += _(" (charging)");
        }
        
        private void update_status_item () {
            if (device.is_reachable) {
                if (device.is_trusted) {
                    status_item.label = _("Device Reachable and Trusted");
                }
                else {
                    status_item.label = _("Device Reachable but Not Trusted");
                }
            } 
            else {
                if (device.is_trusted) {
                    status_item.label = _("Device Trusted but not Reachable");
                }
                else {
    	            status_item.label = _("Device Not Reachable and Not Trusted");
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

        private void update_browse_items () {
            message ("Signal reciveid");                        

            if (device.to_list_dir && !device.is_mounted ())
                device.mount(false);

            var directories = device.get_directories();                                                                                              

            if (device.to_list_dir &&
                directories.length > 0) {                
                for (int i = 0; i < directories.length; i++) {
                    var pair = directories.index (i); 		                        
                    message(pair.get_secound());
                    
                    var tmpMenuItem = new Gtk.MenuItem.with_label (pair.get_secound());                    
                
                    tmpMenuItem.activate.connect (() => {                        
                        device.browse (pair.get_first ());
                    });

                    browse_items_submenu.prepend (tmpMenuItem);
                }	    
                
                browse_items.set_submenu (browse_items_submenu); 

                if (device.to_list_dir &&
                    device.get_directories().length > 0) {  
                    browse_items.visible = true;
                    browse_item.visible = false;  
                }
                else {
                    browse_items.visible = false;
                    browse_item.visible = true;  
                }
            }            
        }
    }
}
