import { application } from "./application"

import AccountSelectorController from "./account_selector_controller"
application.register("account-selector", AccountSelectorController)

import CalendarController from "./calendar_controller"
application.register("calendar", CalendarController)

import DayNavigatorController from "./day_navigator_controller"
application.register("day-navigator", DayNavigatorController)
