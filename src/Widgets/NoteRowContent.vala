/*
* Copyright (C) 2017-2021 Lains
*
* This program is free software; you can redistribute it &&/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/
[GtkTemplate (ui = "/io/github/lainsce/Notejot/noterowcontent.ui")]
public class Notejot.NoteRowContent : He.Bin {
    [GtkChild]
    private unowned Gtk.Image pin;
    [GtkChild]
    private unowned Gtk.Box row_box;

    private Binding? pinned_binding;
    private Binding? color_binding;
    private Gtk.CssProvider provider = new Gtk.CssProvider();

    private string? _color;
    public string? color {
        get { return _color; }
        set {
            if (value == _color)
                return;

            _color = value;
            provider.load_from_data ((uint8[]) "@define-color note_color %s;".printf(_color));
            ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).view_model.update_note_color (_note, _color);
            row_box.get_style_context().add_provider(provider, 1);
        }
    }

    private Note? _note;
    public Note? note {
        get { return _note; }
        set {
            if (value == _note)
                return;

            pinned_binding?.unbind ();
            color_binding?.unbind ();

            _note = value;

            pinned_binding = _note?.bind_property (
                "pinned", pin, "visible", SYNC_CREATE|BIDIRECTIONAL);
            color_binding = _note?.bind_property (
                "color", this, "color", SYNC_CREATE|BIDIRECTIONAL);
        }
    }

    public NoteRowContent (Note note) {
        Object(
            note: note
        );
    }

    construct {
        row_box.add_css_class ("notejot-sidebar-box");
        row_box.get_style_context().add_provider(provider, 1);
    }

    ~NoteRowContent () {
        while (this.get_first_child () != null) {
            var c = this.get_first_child ();
            c.unparent ();
        }
        this.unparent ();
    }

    [GtkCallback]
    string get_subtitle_line () {
        var res = sync_subtitles (note.subtitle);
        return res + " – " + note.text;
    }

    public string sync_subtitles (string subtitle) {
        string res = "";
        try {
            var reg = new Regex("""(?m)^.*, (?<day>\d{2})/(?<month>\d{2}) (?<hour>\d{2})∶(?<minute>\d{2})$""");
            GLib.MatchInfo match;

            if (log != null) {
                if (reg.match (subtitle, 0, out match)) {
                    var e = new GLib.DateTime.now_local ();
                    var d = new DateTime.local (e.get_year (),
                                                int.parse(match.fetch_named ("month")),
                                                int.parse(match.fetch_named ("day")),
                                                int.parse(match.fetch_named ("hour")),
                                                int.parse(match.fetch_named ("minute")),
                                                e.get_second ());

                    res = "%s".printf(TimeUtils.get_relative_datetime_compact(d));
                }
            }
        } catch (GLib.RegexError re) {
            warning ("%s".printf(re.message));
        }

        return res;
    }
}
