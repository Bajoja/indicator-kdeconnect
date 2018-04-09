"""
 Copyright 2016 KDE Connect Indicator Developers
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
"""

import gi
gi.require_version('Nautilus', '3.0')
gi.require_version('Notify', '0.7')
from gi.repository import Nautilus, GObject, Notify
from subprocess import Popen
from os.path import isfile
from urllib.parse import unquote
import re, gettext, locale

# use of _ to set messages to be translated
_ = gettext.gettext

class KDEConnectSendExtension(GObject.GObject, Nautilus.MenuProvider):

    def __init__(self):
        self.devices_file = "/tmp/devices"

    """Inicialize translations to a domain"""
    def setup_gettext(self):
        try:
            locale.setlocale(locale.LC_ALL, "")
            gettext.bindtextdomain("indicator-kdeconnect", "/usr/share/locale")
            gettext.textdomain("indicator-kdeconnect")
        except:
            pass

    """Get a list of reachable devices"""
    def get_reachable_devices(self):
        if not isfile(self.devices_file):
            return

        devices = []
        with open(self.devices_file, 'r') as file:
            data = file.readline()
            while data:
                devices.append(data)
                data = file.readline()

        devices_a=[]
        for device in devices:
            device_name = re.search("(?<=-\s).+(?=:\s)", device).group(0)
            device_id = re.search("(?<=:\s)[_a-z0-9]+", device).group(0).strip()
            devices_a.append({ "name": device_name, "id": device_id })
        return devices_a

    """Send a files with kdeconnect"""
    def send_files(self, menu, files, device_id, device_name):
        for file in files:
            filename = unquote(file.get_uri()[7:])
            Popen(["kdeconnect-cli", "-d", device_id, "--share", filename])

        self.setup_gettext()
        Notify.init("KDEConnect-send")
        Notify.Notification.new(_("Check the device {device_name}").format(device_name=device_name),
                                _("Sending {num_files} file(s)").format(num_files=len(files))
                                ).show()

    """Open Multiple Send Window"""
    def send_to_multiple_devices(self, menu, files):
        args = []
        args.append("kdeconnect-send")

        for file in files:
            args.append(unquote(file.get_uri()[7:]))

        print(args)
        Popen(args)

    """Send selected files"""
    def menu_activate_cb(self, menu, files, device_id, device_name):
        self.send_files(files, device_id, device_name)

    """Get files that user selected"""
    def get_file_items(self, window, files):
        """Ensure there are reachable devices"""
        try:
            devices = self.get_reachable_devices()
        except Exception as e:
            raise Exception("Error while getting reachable devices")

        """if there is no reacheable devices don't show this on context menu"""
        if not devices:
            return

        """Ensure that user only select files"""
        for file in files:
            if file.get_uri_scheme() != 'file' or file.is_directory():
                return

        self.setup_gettext()
        """If user only select file(s) create menu and sub menu"""
        menu = Nautilus.MenuItem(name = 'KdeConnectSendExtension::KDEConnectSend',
                                 label = _('KDEConnect Send To'),
                                 tip = _('send file(s) with kdeconnect'),
                                 icon = 'kdeconnect')

        sub_menu = Nautilus.Menu()

        menu.set_submenu(sub_menu)

        for device in devices:
            item = Nautilus.MenuItem(name='KDEConnectSendExtension::SendFileTo'+device["id"],
                                     label=device["name"])
            item.connect('activate', self.send_files, files, device["id"], device["name"])
            sub_menu.append_item(item)

        if len(devices) > 1:
            item = Nautilus.MenuItem(name='KDEConnectSendExtension::SendFileToMultipleDevices',
            			     label='Multiple Devices')
            item.connect('activate', self.send_to_multiple_devices, files)
            sub_menu.append_item(item)

        return menu,
