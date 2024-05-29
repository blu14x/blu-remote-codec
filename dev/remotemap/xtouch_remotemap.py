from dev.remotemap.remotemap import RemoteMap

remote_map = RemoteMap(manufacturer='blu', model='X-Touch')

x_touch_channels_count = 8
remote_base_channel_step = 8
remote_effects_per_channel = 8


def channel_number_range(with_master: bool = False) -> (int, bool):
    """returns (channel_nr: int, is_master: bool)"""

    channels_count_with_master = x_touch_channels_count + 1

    current_channel_number = 1
    while current_channel_number <= (channels_count_with_master if with_master else x_touch_channels_count):
        yield current_channel_number, (current_channel_number == channels_count_with_master)
        current_channel_number += 1


def channel_focus_range() -> (int, bool, bool):
    """returns (channel_focus_nr: int, is_off: bool, is_master: bool)"""

    channels_count_with_master = x_touch_channels_count + 1

    current_cf_number = 0
    while current_cf_number <= channels_count_with_master:
        is_off = current_cf_number == 0
        is_master = current_cf_number == channels_count_with_master
        yield current_cf_number, is_off, is_master
        current_cf_number += 1


def fader_bank_check_range() -> (int, int):
    """returns (control_item_nr: int, remotable_item_channel_nr: int)"""

    current_channel_number = 1
    while current_channel_number <= remote_base_channel_step:
        yield current_channel_number, current_channel_number + x_touch_channels_count
        current_channel_number += 1


#    _____                              _____                                        _
#   |  __ \                            |  __ \                                      | |
#   | |__) |___  __ _ ___  ___  _ __   | |  | | ___   ___ _   _ _ __ ___   ___ _ __ | |_
#   |  _  // _ \/ _` / __|/ _ \| '_ \  | |  | |/ _ \ / __| | | | '_ ` _ \ / _ \ '_ \| __|
#   | | \ \  __/ (_| \__ \ (_) | | | | | |__| | (_) | (__| |_| | | | | | |  __/ | | | |_
#   |_|  \_\___|\__,_|___/\___/|_| |_| |_____/ \___/ \___|\__,_|_| |_| |_|\___|_| |_|\__|

rs = remote_map.scope(manufacturer='Propellerheads', model='Reason Document')

# Scribble Options
srn = rs.group('srn', ['off', 'on'])  # time code view
ssr = rs.group('ssr', ['off', 'on'])  # global view

rs.map('TC: Name/Value', srn.set_on, g=srn.off, m='hold')
rs.map('TC: Name/Value', srn.set_off, g=srn.on, m='hold')
rs.map('View: Global View', ssr.set_on, g=ssr.off, m='s')
rs.map('View: Global View', ssr.set_off, g=ssr.on, m='f')
rs.div()
rs.map('_SRN', '"off"', g=srn.off)
rs.map('_SRN', '"on"', g=srn.on)
rs.map('_SSR', '"off"', g=ssr.off)
rs.map('_SSR', '"on"', g=ssr.on)
rs.div(2)

# Jog wheel Locators
jog_ll = rs.group('jog_ll', ['on', 'off'])  # jog loop left
jog_lr = rs.group('jog_lr', ['on', 'off'])  # jog loop right
jog_ss = rs.group('jog_ss', ['loop', 'song'])  # jog scroll select
jog_sc = rs.group('jog_sc', ['bar', 'beat'])  # jog scale

rs.map('Nav: Zoom', jog_ss.set_loop, m='sf')
rs.map('Nav: Down', jog_ss.set_song, m='sf')
rs.map('Nav: Left', jog_ll.set_on, m='o', g=jog_ll.off)
rs.map('Nav: Left', jog_ll.set_off, m='s', g=jog_ll.on)
rs.map('Nav: Right', jog_lr.set_on, m='o', g=jog_lr.off)
rs.map('Nav: Right', jog_lr.set_off, m='s', g=jog_lr.on)
rs.map('Nav: Scrub', jog_sc.set_beat, m='o', g=jog_sc.bar)
rs.map('Nav: Scrub', jog_sc.set_bar, m='s', g=jog_sc.beat)
rs.div()
rs.map('Jog Wheel', 'Song Position', s=61440, g=[jog_ss.song, jog_sc.bar])
rs.map('Jog Wheel', 'Song Position', s=15360, g=[jog_ss.song, jog_sc.beat])
rs.map('Jog Wheel', 'Left Loop', s=61440, g=[jog_ss.loop, jog_sc.bar, jog_ll.on])
rs.map('Jog Wheel', 'Left Loop', s=15360, g=[jog_ss.loop, jog_sc.beat, jog_ll.on])
rs.map('Jog Wheel Clone 1', 'Right Loop', s=61440, g=[jog_ss.loop, jog_sc.bar, jog_lr.on])
rs.map('Jog Wheel Clone 1', 'Right Loop', s=15360, g=[jog_ss.loop, jog_sc.beat, jog_lr.on])
rs.div(2)

# Transport
gtl = rs.group('gtl', ['off', 'on'])  # go to locator
tcf = rs.group('tcf', ['beats', 'smpte'])  # time code format

rs.map('Tr: Drop', gtl.set_on, m='s_hold', g=gtl.off)
rs.map('Tr: Drop', gtl.set_off, m='f_hold', g=gtl.on)
rs.div()
rs.map('Tr: Rewind', 'Rewind', m='sf', g=gtl.off)
rs.map('Tr: Fast Forward', 'Fast Forward', m='sf', g=gtl.off)
rs.map('Tr: Stop', 'Stop', m='sf', g=gtl.off)
rs.map('Tr: Play', 'Play', m='sf', g=gtl.off)
rs.map('Tr: Record', 'Record', m='sf', g=gtl.off)
rs.div()
rs.map('Tr: Rewind', 'Goto Left Locator', m='sf', g=gtl.on)
rs.map('Tr: Fast Forward', 'Goto Right Locator', m='sf', g=gtl.on)
rs.div(2)

# Utility
rs.map('Aut: Read/Off', 'Reset Automation Override', m='os')
rs.map('Tr: Cycle', 'Loop On/Off', m='sf')
rs.map('Tr: Click', 'Click On/Off', m='sf')
rs.div(2)

# TimeCode
rs.map('TC: SMPTE/Beats', tcf.set_smpte, g=tcf.beats)
rs.map('TC: SMPTE/Beats', tcf.set_beats, g=tcf.smpte)
rs.div()
rs.map('TC: Beats LED', '1', g=tcf.beats)
rs.map('TC: Bars', 'Bar Position', m='decimal_trailing', g=tcf.beats)
rs.map('TC: Beats', 'Beat Position', m='decimal_trailing', g=tcf.beats)
rs.map('TC: Sub Division', 'Sixteenth Position', m='decimal_trailing', g=tcf.beats)
rs.map('TC: Ticks', 'Tick Position', g=tcf.beats)
rs.div()
rs.map('TC: SMPTE LED', '1', g=tcf.smpte)
rs.map('TC: Bars', 'Hour Position', m='decimal_trailing', g=tcf.smpte)
rs.map('TC: Beats', 'Minute Position', m='decimal_trailing', g=tcf.smpte)
rs.map('TC: Sub Division', 'Second Position', m='decimal_trailing', g=tcf.smpte)
rs.map('TC: Ticks', 'Millisecond Position', g=tcf.smpte)

#    _____                              __  __           _               _____           _   _
#   |  __ \                            |  \/  |         | |             / ____|         | | (_)
#   | |__) |___  __ _ ___  ___  _ __   | \  / | __ _ ___| |_ ___ _ __  | (___   ___  ___| |_ _  ___  _ __
#   |  _  // _ \/ _` / __|/ _ \| '_ \  | |\/| |/ _` / __| __/ _ \ '__|  \___ \ / _ \/ __| __| |/ _ \| '_ \
#   | | \ \  __/ (_| \__ \ (_) | | | | | |  | | (_| \__ \ ||  __/ |     ____) |  __/ (__| |_| | (_) | | | |
#   |_|  \_\___|\__,_|___/\___/|_| |_| |_|  |_|\__,_|___/\__\___|_|    |_____/ \___|\___|\__|_|\___/|_| |_|

rms = remote_map.scope(manufacturer='Propellerheads', model='Reason Master Section')
rms.map('_S', '"Reason Master Section"')

# Channel Focus
cf = rms.group('cf', ['off', 'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9'])
for nr, is_master in channel_number_range(True):
    rms.map('Main: Flip' if is_master else f'Ch {nr}: Select', getattr(cf, f'set_c{nr}'), m='o', g=cf.off)
    rms.map('Main: Flip', cf.set_off, m='s', g=getattr(cf, f'c{nr}'))
    rms.map('TC: Assignment', '"Ma"' if is_master else f'"{nr}"', g=getattr(cf, f'c{nr}'))
    rms.map('_CF', f'"{nr}"', g=getattr(cf, f'c{nr}'))
    rms.div()
rms.div()

# Encoder Assign
# ea = rms.group('ea', ['inp', 'dyn', 'eq', 'ins', 'snd', 'fdr'])  # encoder assign
ea = rms.group('ea', ['fdr', 'inp', 'dyn', 'eq', 'ins', 'snd'])  # encoder assign
ea_mas = rms.group('ea_mas', ['cmp', 'snd', 'ins', 'rtn'])  # encoder assign on master

rms.map('EA: Track', ea.set_inp, m='sf')
rms.map('EA: Pan/Surround', ea.set_dyn, m='sf')
rms.map('EA: Eq', ea.set_eq, m='sf')
rms.map('EA: Send', ea.set_ins, m='sf')
rms.map('EA: Plug-In', ea.set_snd, m='sf')
rms.map('EA: Inst', ea.set_fdr, m='sf')
rms.div()
rms.map('EA: Track', '0', m='o', g=cf.c9)
rms.map('EA: Pan/Surround', ea_mas.set_cmp, m='sf', g=cf.c9)
rms.map('EA: Eq', ea_mas.set_snd, m='sf', g=cf.c9)
rms.map('EA: Send', ea_mas.set_rtn, m='sf', g=cf.c9)
rms.map('EA: Plug-In', ea_mas.set_ins, m='sf', g=cf.c9)
rms.map('EA: Inst', '0', m='o', g=cf.c9)
rms.div()
rms.map('_EA', '"Input"', g=ea.inp)
rms.map('_EA', '"Dynamics"', g=ea.dyn)
rms.map('_EA', '"Equalizer"', g=ea.eq)
rms.map('_EA', '"Inserts"', g=ea.ins)
rms.map('_EA', '"Send"', g=ea.snd)
rms.map('_EA', '"Fader"', g=ea.fdr)
rms.div()
rms.map('_EA', '"Master Compressor"', g=[cf.c9, ea_mas.cmp])
rms.map('_EA', '"FX Send"', g=[cf.c9, ea_mas.snd])
rms.map('_EA', '"Master Inserts"', g=[cf.c9, ea_mas.ins])
rms.map('_EA', '"FX Return"', g=[cf.c9, ea_mas.rtn])
rms.div(2)

# Encoder Assign - Groups / Mods
ea_dyn = rms.group('ea_dyn', ['cmp', 'gat'])  # encoder assign - dynamics
ea_eq = rms.group('ea_eq', ['lpf', 'hpf'])  # encoder assign - equalizer
ea_eq_m = rms.group('ea_eq_m', ['off', 'm1'])  # encoder assign - equalizer mod
ea_snd = rms.group('ea_snd', ['fx1', 'fx2', 'fx3', 'fx4', 'fx5', 'fx6', 'fx7', 'fx8'])  # encoder assign - sends
ea_fx = rms.group('ea_fx', ['fx1_4', 'fx5_8'])  # encoder assign - channel focus sends
ea_fdr_m = rms.group('ea_fdr_m', ['off', 'm1'])  # encoder assign - fader mod

rms.map('_G', '"Low Pass Filter"', g=[cf.off, ea.eq, ea_eq.lpf])
rms.map('_G', '"High Pass Filter"', g=[cf.off, ea.eq, ea_eq.hpf])
rms.div()
rms.map('_G', '"Send 1"', g=[cf.off, ea.snd, ea_snd.fx1])
rms.map('_G', '"Send 2"', g=[cf.off, ea.snd, ea_snd.fx2])
rms.map('_G', '"Send 3"', g=[cf.off, ea.snd, ea_snd.fx3])
rms.map('_G', '"Send 4"', g=[cf.off, ea.snd, ea_snd.fx4])
rms.map('_G', '"Send 5"', g=[cf.off, ea.snd, ea_snd.fx5])
rms.map('_G', '"Send 6"', g=[cf.off, ea.snd, ea_snd.fx6])
rms.map('_G', '"Send 7"', g=[cf.off, ea.snd, ea_snd.fx7])
rms.map('_G', '"Send 8"', g=[cf.off, ea.snd, ea_snd.fx8])
rms.div()
rms.map('_G', '"Comp"', g=[ea.dyn, ea_dyn.cmp])  # watch out. no channel focus set
rms.map('_G', '"Gate"', g=[ea.dyn, ea_dyn.gat])  # watch out. no channel focus set
rms.div()
rms.map('_G', '"Snd FX 1-4"', g=[ea.snd, ea_fx.fx1_4])  # watch out. no channel focus set
rms.map('_G', '"Snd FX 5-8"', g=[ea.snd, ea_fx.fx5_8])  # watch out. no channel focus set
rms.div()
rms.map('_G', '"Snd FX 1-4"', g=[cf.c9, ea_mas.snd, ea_fx.fx1_4])
rms.map('_G', '"Snd FX 5-8"', g=[cf.c9, ea_mas.snd, ea_fx.fx5_8])
rms.div()
rms.map('_G', '"Fx Rtn 1-4"', g=[cf.c9, ea_mas.rtn, ea_fx.fx1_4])
rms.map('_G', '"Fx Rtn 5-8"', g=[cf.c9, ea_mas.rtn, ea_fx.fx5_8])
rms.div(2)

rms.map('_M', '"Mid F Freq"', g=[ea.eq, ea_eq_m.off])  # watch out. no channel focus set
rms.map('_M', '"Mid F Q"', g=[ea.eq, ea_eq_m.m1])  # watch out. no channel focus set
rms.div()
rms.map('_M', '"Panorama"', g=[cf.off, ea.fdr, ea_fdr_m.off])
rms.map('_M', '"Width"', g=[cf.off, ea.fdr, ea_fdr_m.m1])
rms.div()

# Fader Bank
rms.map('_RBC', 'Remote Base Channel')
for c_nr, r_nr in fader_bank_check_range():
    rms.map(f'_FBC {c_nr}', f'Channel {r_nr} Channel Name')
rms.div(2)

jog = rms.group('jog', ['off', 'on'])  # jog wheel enabled

rms.map('Nav: Up', jog.set_on, g=jog.off, m='s')
rms.map('Nav: Up', jog.set_off, g=jog.on, m='f')
rms.div()
rms.map('_JRN', '"Remote Base Channel Delta"', g=[jog.on, cf.off])
rms.map('Jog Wheel', 'Remote Base Channel Delta', g=[jog.on, cf.off])
rms.map('_JRN', '""', g=jog.on)
rms.map('Jog Wheel', '0', g=jog.on)
rms.map('Jog Wheel Clone 1', '0', g=jog.on)
rms.map('Jog Wheel Clone 2', '0', g=jog.on)
rms.map('Nav: Zoom', '0', g=jog.on)
rms.map('Nav: Down', '0', g=jog.on)
rms.div()
rms.map('Page: FB Left', 'Previous 8 Remote Base Channel', g=cf.off, m='os')
rms.map('Page: Ch Left', 'Previous Remote Base Channel', g=cf.off, m='os')
rms.map('Page: FB Right', 'Next 8 Remote Base Channel', g=cf.off, m='os')
rms.map('Page: Ch Right', 'Next Remote Base Channel', g=cf.off, m='os')
rms.div(2)

# Channel Focus + Encoder Assign Groups & Mods
for cf_v, cf_is_off, cf_is_master in channel_focus_range():
    cf_g = cf.off if cf_v == 0 else getattr(cf, f'c{cf_v}')

    if cf_is_off:
        rms.map('Func: F1', ea_dyn.set_cmp, m='sf', g=[cf_g, ea.dyn])
        rms.map('Func: F2', ea_dyn.set_gat, m='sf', g=[cf_g, ea.dyn])
        rms.map('Func: F1', ea_eq.set_lpf, m='sf', g=[cf_g, ea.eq])
        rms.map('Func: F2', ea_eq.set_hpf, m='sf', g=[cf_g, ea.eq])
        rms.map('Mod: Shift', ea_fdr_m.set_m1, m='s_hold', g=[cf_g, ea.fdr, ea_fdr_m.off])
        rms.map('Mod: Shift', ea_fdr_m.set_off, m='s_hold', g=[cf_g, ea.fdr, ea_fdr_m.m1])

        for fx in range(1, remote_effects_per_channel + 1):
            rms.map(f'Func: F{fx}', getattr(ea_snd, f'set_fx{fx}'), m='sf', g=[cf_g, ea.snd])
        rms.div(2)

        rms.map('Main: Fader', 'Master Level', g=[cf_g])
        rms.div()
        for nr, _ in channel_number_range():
            # encoder assing (none) - general
            rms.map(f'Ch {nr}: Scribble Header', f'Channel {nr} Channel Name', m='rms', g=[cf_g])
            rms.map(f'Ch {nr}: Scribble Color', '"header_suffix"', g=[cf_g])
            rms.map(f'Ch {nr}: Level Indicator', f'Channel {nr} VU Meter', g=[cf_g])
            rms.map(f'Ch {nr}: Fader', f'Channel {nr} Level', g=[cf_g])
            rms.map(f'Ch {nr}: Solo', f'Channel {nr} Solo', g=[cf_g])
            rms.map(f'Ch {nr}: Mute', f'Channel {nr} Mute', g=[cf_g])
            rms.div()

            # encoder assing (none) - input
            rms.map(f'Ch {nr}: Encoder', f'Channel {nr} Input Gain', m='bip', g=[cf_g, ea.inp])
            rms.map(f'Ch {nr}: Record', f'Channel {nr} Invert Phase', g=[cf_g, ea.inp])
            rms.div()

            # encoder assing (none) - dynamics
            rms.map(f'Ch {nr}: Encoder', f'Channel {nr} C Threshold', m='fill', g=[cf_g, ea.dyn, ea_dyn.cmp])
            rms.map(f'Ch {nr}: Record', f'Channel {nr} Comp On', g=[cf_g, ea.dyn, ea_dyn.cmp])
            rms.map(f'Ch {nr}: Encoder', f'Channel {nr} G Threshold', m='fill', g=[cf_g, ea.dyn, ea_dyn.gat])
            rms.map(f'Ch {nr}: Record', f'Channel {nr} Gate On', g=[cf_g, ea.dyn, ea_dyn.gat])
            rms.div()

            # encoder assing (none) - equalizer
            rms.map(f'Ch {nr}: Encoder', f'Channel {nr} LPF Frequency', m='fill', g=[cf_g, ea.eq, ea_eq.lpf])
            rms.map(f'Ch {nr}: Record', f'Channel {nr} LPF On', g=[cf_g, ea.eq, ea_eq.lpf])
            rms.map(f'Ch {nr}: Encoder', f'Channel {nr} HPF Frequency', m='fill_mir_rev', g=[cf_g, ea.eq, ea_eq.hpf])
            rms.map(f'Ch {nr}: Record', f'Channel {nr} HPF On', g=[cf_g, ea.eq, ea_eq.hpf])
            rms.div()

            # encoder assing (none) - inserts
            rms.map(f'Ch {nr}: Record', f'Channel {nr} Bypass Insert FX', g=[cf_g, ea.ins])
            rms.div()

            # encoder assing (none) - sends
            for fx in range(1, remote_effects_per_channel + 1):
                ea_snd_g = getattr(ea_snd, f'fx{fx}')
                rms.map(f'Ch {nr}: Encoder', f'Channel {nr} FX{fx} Send Level', m='fill', g=[cf_g, ea.snd, ea_snd_g])
                rms.map(f'Ch {nr}: Record', f'Channel {nr} FX{fx} Send On', g=[cf_g, ea.snd, ea_snd_g])
            rms.div()

            # encoder assign - fader
            rms.map(f'Ch {nr}: Encoder', f'Channel {nr} Pan', m='rms_pan', g=[cf_g, ea.fdr, ea_fdr_m.off])
            rms.map(f'Ch {nr}: Encoder', f'Channel {nr} Width', m='fill_spread', g=[cf_g, ea.fdr, ea_fdr_m.m1])
            rms.div(2)

    elif cf_is_master:
        rms.map('Func: F1', ea_fx.set_fx5_8, m='sf', g=[cf_g, ea_mas.snd])
        rms.map('Func: F2', ea_fx.set_fx1_4, m='sf', g=[cf_g, ea_mas.snd])
        rms.map('Func: F1', ea_fx.set_fx5_8, m='sf', g=[cf_g, ea_mas.rtn])
        rms.map('Func: F2', ea_fx.set_fx1_4, m='sf', g=[cf_g, ea_mas.rtn])
        rms.div()
        # encoder assign (master) - general
        rms.map('Ch 1: Scribble Header', '"Master"', m='rms', g=[cf_g])
        rms.map('Ch 1: Scribble Color', '"white"', g=[cf_g])
        rms.map('Ch 2: Scribble Color', '"mimic_1"', g=[cf_g])
        rms.map('Ch 3: Scribble Color', '"mimic_1"', g=[cf_g])
        rms.map('Ch 4: Scribble Color', '"mimic_1"', g=[cf_g])
        rms.map('Ch 5: Scribble Color', '"mimic_1"', g=[cf_g])
        rms.map('Ch 6: Scribble Color', '"mimic_1"', g=[cf_g])
        rms.map('Ch 7: Scribble Color', '"mimic_1"', g=[cf_g])
        rms.map('Ch 8: Scribble Color', '"mimic_1"', g=[cf_g])

        rms.map('Ch 1: Encoder', 'Ctrl Room Level', m='fill', g=[cf_g])
        rms.map('Ch 1: Fader', 'Master Level', g=[cf_g])
        rms.map('Ch 1: Level Indicator', 'Master Level Meter Left', g=[cf_g])
        rms.div()
        # encoder assign (master) - master compressor
        rms.map('Ch 3: Record', 'Compressor On', g=[cf_g, ea_mas.cmp])
        rms.map('Ch 7: Record', 'Key On', g=[cf_g, ea_mas.cmp])
        rms.map('Ch 3: Encoder', 'Threshold', m='fill', g=[cf_g, ea_mas.cmp])
        rms.map('Ch 4: Encoder', 'Ratio', m='fill', g=[cf_g, ea_mas.cmp])
        rms.map('Ch 5: Encoder', 'Attack', m='fill', g=[cf_g, ea_mas.cmp])
        rms.map('Ch 6: Encoder', 'Release', m='fill', g=[cf_g, ea_mas.cmp])
        rms.map('Ch 7: Encoder', 'Make-Up Gain', m='fill', g=[cf_g, ea_mas.cmp])
        rms.div()
        # encoder assign (master) - FX Send
        rms.map('Ch 4: Level Indicator', 'FX1 Send Level Meter', g=[cf_g, ea_mas.snd, ea_fx.fx1_4])
        rms.map('Ch 5: Level Indicator', 'FX2 Send Level Meter', g=[cf_g, ea_mas.snd, ea_fx.fx1_4])
        rms.map('Ch 6: Level Indicator', 'FX3 Send Level Meter', g=[cf_g, ea_mas.snd, ea_fx.fx1_4])
        rms.map('Ch 7: Level Indicator', 'FX4 Send Level Meter', g=[cf_g, ea_mas.snd, ea_fx.fx1_4])
        rms.map('Ch 4: Level Indicator', 'FX5 Send Level Meter', g=[cf_g, ea_mas.snd, ea_fx.fx5_8])
        rms.map('Ch 5: Level Indicator', 'FX6 Send Level Meter', g=[cf_g, ea_mas.snd, ea_fx.fx5_8])
        rms.map('Ch 6: Level Indicator', 'FX7 Send Level Meter', g=[cf_g, ea_mas.snd, ea_fx.fx5_8])
        rms.map('Ch 7: Level Indicator', 'FX8 Send Level Meter', g=[cf_g, ea_mas.snd, ea_fx.fx5_8])
        rms.map('Ch 4: Fader', 'FX1 Send Level', g=[cf_g, ea_mas.snd, ea_fx.fx1_4])
        rms.map('Ch 5: Fader', 'FX2 Send Level', g=[cf_g, ea_mas.snd, ea_fx.fx1_4])
        rms.map('Ch 6: Fader', 'FX3 Send Level', g=[cf_g, ea_mas.snd, ea_fx.fx1_4])
        rms.map('Ch 7: Fader', 'FX4 Send Level', g=[cf_g, ea_mas.snd, ea_fx.fx1_4])
        rms.map('Ch 4: Fader', 'FX5 Send Level', g=[cf_g, ea_mas.snd, ea_fx.fx5_8])
        rms.map('Ch 5: Fader', 'FX6 Send Level', g=[cf_g, ea_mas.snd, ea_fx.fx5_8])
        rms.map('Ch 6: Fader', 'FX7 Send Level', g=[cf_g, ea_mas.snd, ea_fx.fx5_8])
        rms.map('Ch 7: Fader', 'FX8 Send Level', g=[cf_g, ea_mas.snd, ea_fx.fx5_8])
        rms.div()
        # encoder assign (master) - inserts
        rms.map('Ch 3: Record', 'Bypass Insert FX', g=[cf_g, ea_mas.ins])
        rms.div()
        # encoder assing (master) - FX Return
        rms.map('Ch 4: Level Indicator', 'FX1 Return Level Meter', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 5: Level Indicator', 'FX2 Return Level Meter', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 6: Level Indicator', 'FX3 Return Level Meter', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 7: Level Indicator', 'FX4 Return Level Meter', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 4: Level Indicator', 'FX5 Return Level Meter', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 5: Level Indicator', 'FX6 Return Level Meter', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 6: Level Indicator', 'FX7 Return Level Meter', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 7: Level Indicator', 'FX8 Return Level Meter', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 4: Fader', 'FX1 Return Level', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 5: Fader', 'FX2 Return Level', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 6: Fader', 'FX3 Return Level', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 7: Fader', 'FX4 Return Level', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 4: Fader', 'FX5 Return Level', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 5: Fader', 'FX6 Return Level', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 6: Fader', 'FX7 Return Level', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 7: Fader', 'FX8 Return Level', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 4: Encoder', 'FX1 Pan', m='bip', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 5: Encoder', 'FX2 Pan', m='bip', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 6: Encoder', 'FX3 Pan', m='bip', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 7: Encoder', 'FX4 Pan', m='bip', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 4: Encoder', 'FX5 Pan', m='bip', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 5: Encoder', 'FX6 Pan', m='bip', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 6: Encoder', 'FX7 Pan', m='bip', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 7: Encoder', 'FX8 Pan', m='bip', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 4: Record', 'FX1 Mute', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 5: Record', 'FX2 Mute', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 6: Record', 'FX3 Mute', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 7: Record', 'FX4 Mute', g=[cf_g, ea_mas.rtn, ea_fx.fx1_4])
        rms.map('Ch 4: Record', 'FX5 Mute', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 5: Record', 'FX6 Mute', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 6: Record', 'FX7 Mute', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.map('Ch 7: Record', 'FX8 Mute', g=[cf_g, ea_mas.rtn, ea_fx.fx5_8])
        rms.div(2)

    else:
        rms.map('Func: F1', ea_dyn.set_cmp, m='sf', g=[cf_g, ea.dyn])
        rms.map('Func: F2', ea_dyn.set_gat, m='sf', g=[cf_g, ea.dyn])
        rms.map('Mod: Shift', ea_eq_m.set_m1, m='s_hold', g=[cf_g, ea.eq, ea_eq_m.off])
        rms.map('Mod: Shift', ea_eq_m.set_off, m='s_hold', g=[cf_g, ea.eq, ea_eq_m.m1])
        rms.map('Func: F1', ea_fx.set_fx5_8, m='sf', g=[cf_g, ea.snd])
        rms.map('Func: F2', ea_fx.set_fx1_4, m='sf', g=[cf_g, ea.snd])

        rms.div()
        # encoder assing (1-8) - general
        rms.map(f'Ch 1: Scribble Header', f'Channel {cf_v} Channel Name', m='rms', g=[cf_g])
        rms.map('Ch 1: Scribble Color', '"header_suffix"', g=[cf_g])
        rms.map('Ch 2: Scribble Color', '"mimic_1"', g=[cf_g])
        rms.map('Ch 3: Scribble Color', '"mimic_1"', g=[cf_g])
        rms.map('Ch 4: Scribble Color', '"mimic_1"', g=[cf_g])
        rms.map('Ch 5: Scribble Color', '"mimic_1"', g=[cf_g])
        rms.map('Ch 6: Scribble Color', '"mimic_1"', g=[cf_g])
        rms.map('Ch 7: Scribble Color', '"mimic_1"', g=[cf_g])
        rms.map('Ch 8: Scribble Color', '"mimic_1"', g=[cf_g])
        rms.map('Ch 1: Encoder', f'Channel {cf_v} Pan', m='rms_pan', g=[cf_g])
        rms.map('Ch 1: Level Indicator', f'Channel {cf_v} VU Meter', g=[cf_g])
        rms.map('Ch 1: Fader', f'Channel {cf_v} Level', g=[cf_g])
        rms.map('Ch 1: Solo', f'Channel {cf_v} Solo', g=[cf_g])
        rms.map('Ch 1: Mute', f'Channel {cf_v} Mute', g=[cf_g])
        rms.div()
        # encoder assing (1-8) - input
        rms.map('Ch 3: Encoder', f'Channel {cf_v} Input Gain', m='bip', g=[cf_g, ea.inp])
        rms.map('Ch 3: Record', f'Channel {cf_v} Invert Phase', g=[cf_g, ea.inp])
        rms.map('Ch 4: Record', f'Channel {cf_v} Insert Pre', g=[cf_g, ea.inp])
        rms.map('Ch 5: Record', f'Channel {cf_v} Dyn Post EQ', g=[cf_g, ea.inp])
        rms.div()
        # encoder assing (1-8) - dynamics
        rms.map('Ch 3: Encoder Led Left', f'Channel {cf_v} Gate Gain Reduction', m='rms_gatcmb', g=[cf_g, ea.dyn])
        rms.map('Ch 3: Encoder Led Right', f'Channel {cf_v} Comp Gain Reduction', m='rms_gatcmb', g=[cf_g, ea.dyn])

        rms.map('Ch 3: Record', f'Channel {cf_v} Key', g=[cf_g, ea.dyn])

        rms.map('Ch 5: Record', f'Channel {cf_v} Comp On', g=[cf_g, ea.dyn, ea_dyn.cmp])
        rms.map('Ch 6: Record', f'Channel {cf_v} C Peak', g=[cf_g, ea.dyn, ea_dyn.cmp])
        rms.map('Ch 7: Record', f'Channel {cf_v} C Fast Atk', g=[cf_g, ea.dyn, ea_dyn.cmp])
        rms.map('Ch 5: Encoder', f'Channel {cf_v} C Ratio', m='fill', g=[cf_g, ea.dyn, ea_dyn.cmp])
        rms.map('Ch 6: Encoder', f'Channel {cf_v} C Threshold', m='fill', g=[cf_g, ea.dyn, ea_dyn.cmp])
        rms.map('Ch 7: Encoder', f'Channel {cf_v} C Release', m='fill', g=[cf_g, ea.dyn, ea_dyn.cmp])

        rms.map('Ch 5: Record', f'Channel {cf_v} Gate On', g=[cf_g, ea.dyn])
        rms.map('Ch 6: Record', f'Channel {cf_v} Expander', g=[cf_g, ea.dyn])
        rms.map('Ch 7: Record', f'Channel {cf_v} G Fast Atk', g=[cf_g, ea.dyn])
        rms.map('Ch 5: Encoder', f'Channel {cf_v} G Range', m='fill', g=[cf_g, ea.dyn, ea_dyn.gat])
        rms.map('Ch 6: Encoder', f'Channel {cf_v} G Threshold', m='fill', g=[cf_g, ea.dyn, ea_dyn.gat])
        rms.map('Ch 7: Encoder', f'Channel {cf_v} G Release', m='fill', g=[cf_g, ea.dyn, ea_dyn.gat])
        rms.map('Ch 8: Encoder', f'Channel {cf_v} G Hold', m='fill', g=[cf_g, ea.dyn, ea_dyn.gat])
        rms.div()
        # encoder assing (1-8) - equalizer
        rms.map('Ch 3: Record', f'Channel {cf_v} HPF On', g=[cf_g, ea.eq])
        rms.map('Ch 4: Record', f'Channel {cf_v} LF Bell', g=[cf_g, ea.eq])
        rms.map('Ch 5: Record', f'Channel {cf_v} EQ On', g=[cf_g, ea.eq])
        rms.map('Ch 6: Record', f'Channel {cf_v} EQ E Mode', g=[cf_g, ea.eq])
        rms.map('Ch 7: Record', f'Channel {cf_v} HF Bell', g=[cf_g, ea.eq])
        rms.map('Ch 8: Record', f'Channel {cf_v} LPF On', g=[cf_g, ea.eq])
        rms.map('Ch 3: Encoder', f'Channel {cf_v} HPF Frequency', m='fill_mir_rev', g=[cf_g, ea.eq])
        rms.map('Ch 4: Encoder', f'Channel {cf_v} LF Frequency', m='dot_blur', g=[cf_g, ea.eq])
        rms.map('Ch 5: Encoder', f'Channel {cf_v} LMF Frequency', m='dot_blur', g=[cf_g, ea.eq])
        rms.map('Ch 6: Encoder', f'Channel {cf_v} HMF Frequency', m='dot_blur', g=[cf_g, ea.eq])
        rms.map('Ch 7: Encoder', f'Channel {cf_v} HF Frequency', m='dot_blur', g=[cf_g, ea.eq])
        rms.map('Ch 8: Encoder', f'Channel {cf_v} LPF Frequency', m='fill', g=[cf_g, ea.eq])
        rms.map('Ch 5: Encoder', f'Channel {cf_v} LMF Q', m='fill_spread_rev', g=[cf_g, ea.eq, ea_eq_m.m1])
        rms.map('Ch 6: Encoder', f'Channel {cf_v} HMF Q', m='fill_spread_rev', g=[cf_g, ea.eq, ea_eq_m.m1])
        rms.map('Ch 4: Fader', f'Channel {cf_v} LF Gain', g=[cf_g, ea.eq])
        rms.map('Ch 5: Fader', f'Channel {cf_v} LMF Gain', g=[cf_g, ea.eq])
        rms.map('Ch 6: Fader', f'Channel {cf_v} HMF Gain', g=[cf_g, ea.eq])
        rms.map('Ch 7: Fader', f'Channel {cf_v} HF Gain', g=[cf_g, ea.eq])
        rms.div()
        # encoder assign (master) - inserts
        rms.map('Ch 3: Record', f'Channel {cf_v} Bypass Insert FX', g=[cf_g, ea.ins])
        rms.div()
        # encoder assign (master) - FX Send
        rms.map('Ch 4: Encoder', 'FX1 Send Level', m='fill', g=[cf_g, ea.snd, ea_fx.fx1_4])
        rms.map('Ch 5: Encoder', 'FX2 Send Level', m='fill', g=[cf_g, ea.snd, ea_fx.fx1_4])
        rms.map('Ch 6: Encoder', 'FX3 Send Level', m='fill', g=[cf_g, ea.snd, ea_fx.fx1_4])
        rms.map('Ch 7: Encoder', 'FX4 Send Level', m='fill', g=[cf_g, ea.snd, ea_fx.fx1_4])
        rms.map('Ch 4: Encoder', 'FX5 Send Level', m='fill', g=[cf_g, ea.snd, ea_fx.fx5_8])
        rms.map('Ch 5: Encoder', 'FX6 Send Level', m='fill', g=[cf_g, ea.snd, ea_fx.fx5_8])
        rms.map('Ch 6: Encoder', 'FX7 Send Level', m='fill', g=[cf_g, ea.snd, ea_fx.fx5_8])
        rms.map('Ch 7: Encoder', 'FX8 Send Level', m='fill', g=[cf_g, ea.snd, ea_fx.fx5_8])
        rms.div()
        # encoder assing (1-8) - fader
        rms.map('Ch 3: Encoder', f'Channel {cf_v} Width', m='fill_spread', g=[cf_g, ea.fdr])
        rms.div(2)
