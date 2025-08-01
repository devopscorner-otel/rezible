import { getMeetingScheduleOptions } from "$lib/api";
import type { Getter } from "$lib/utils.svelte";
import { createQuery } from "@tanstack/svelte-query";
import { Context, watch } from "runed";

export class MeetingScheduleViewState {
	scheduleId = $state<string>(null!);

	constructor(idFn: Getter<string>) {
		this.scheduleId = idFn();
		watch(idFn, id => {this.scheduleId = id});
	}

	query = createQuery(() => getMeetingScheduleOptions({ path: { id: this.scheduleId } }));
	title = $derived(this.query.data?.data.attributes.name);
}

const ctx = new Context<MeetingScheduleViewState>("meetingScheduleView");
export const setMeetingScheduleViewState = (idFn: Getter<string>) => ctx.set(new MeetingScheduleViewState(idFn));
export const useMeetingScheduleViewState = () => ctx.get();