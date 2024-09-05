#!/bin/bash
#
# Run checks related to code quality.
#
# This script is intended for both the CI and to check locally that code standards are
# respected. We run doctests here (currently some files only), and we
# validate formatting error in docstrings.
#
# Usage:
#   $ ./ci/code_checks.sh               # run all checks
#   $ ./ci/code_checks.sh code          # checks on imported code
#   $ ./ci/code_checks.sh doctests      # run doctests
#   $ ./ci/code_checks.sh docstrings    # validate docstring errors
#   $ ./ci/code_checks.sh single-docs   # check single-page docs build warning-free
#   $ ./ci/code_checks.sh notebooks     # check execution of documentation notebooks

set -uo pipefail

if [[ -v 1 ]]; then
    CHECK=$1
else
    # script will fail if it uses an unset variable (i.e. $1 is not provided)
    CHECK=""
fi

[[ -z "$CHECK" || "$CHECK" == "code" || "$CHECK" == "doctests" || "$CHECK" == "docstrings" || "$CHECK" == "single-docs" || "$CHECK" == "notebooks" ]] || \
    { echo "Unknown command $1. Usage: $0 [code|doctests|docstrings|single-docs|notebooks]"; exit 9999; }

BASE_DIR="$(dirname $0)/.."
RET=0

### CODE ###
if [[ -z "$CHECK" || "$CHECK" == "code" ]]; then

    MSG='Check import. No warnings, and blocklist some optional dependencies' ; echo $MSG
    python -W error -c "
import sys
import pandas

blocklist = {'bs4', 'gcsfs', 'html5lib', 'http', 'ipython', 'jinja2', 'hypothesis',
             'lxml', 'matplotlib', 'openpyxl', 'py', 'pytest', 's3fs', 'scipy',
             'tables', 'urllib.request', 'xlrd', 'xlsxwriter'}

# GH#28227 for some of these check for top-level modules, while others are
#  more specific (e.g. urllib.request)
import_mods = set(m.split('.')[0] for m in sys.modules) | set(sys.modules)
mods = blocklist & import_mods
if mods:
    sys.stderr.write('err: pandas should not import: {}\n'.format(', '.join(mods)))
    sys.exit(len(mods))
    "
    RET=$(($RET + $?)) ; echo $MSG "DONE"

fi

### DOCTESTS ###
if [[ -z "$CHECK" || "$CHECK" == "doctests" ]]; then

    MSG='Python and Cython Doctests' ; echo $MSG
    python -c 'import pandas as pd; pd.test(run_doctests=True)'
    RET=$(($RET + $?)) ; echo $MSG "DONE"

fi

### DOCSTRINGS ###
if [[ -z "$CHECK" || "$CHECK" == "docstrings" ]]; then

    MSG='Validate Docstrings' ; echo $MSG
    $BASE_DIR/scripts/validate_docstrings.py \
        --format=actions \
        -i ES01 `# For now it is ok if docstrings are missing the extended summary` \
        -i "pandas.Series.dt PR01" `# Accessors are implemented as classes, but we do not document the Parameters section` \
        -i "pandas.NA SA01" \
        -i "pandas.Period.freq GL08" \
        -i "pandas.Period.ordinal GL08" \
        -i "pandas.Period.to_timestamp SA01" \
        -i "pandas.PeriodDtype.freq SA01" \
        -i "pandas.RangeIndex.from_range PR01,SA01" \
        -i "pandas.RangeIndex.start SA01" \
        -i "pandas.RangeIndex.step SA01" \
        -i "pandas.RangeIndex.stop SA01" \
        -i "pandas.Series.cat.add_categories PR01,PR02" \
        -i "pandas.Series.cat.as_ordered PR01" \
        -i "pandas.Series.cat.as_unordered PR01" \
        -i "pandas.Series.cat.remove_categories PR01,PR02" \
        -i "pandas.Series.cat.remove_unused_categories PR01" \
        -i "pandas.Series.cat.rename_categories PR01,PR02" \
        -i "pandas.Series.cat.reorder_categories PR01,PR02" \
        -i "pandas.Series.cat.set_categories PR01,PR02" \
        -i "pandas.Series.dt.as_unit PR01,PR02" \
        -i "pandas.Series.dt.ceil PR01,PR02" \
        -i "pandas.Series.dt.day_name PR01,PR02" \
        -i "pandas.Series.dt.floor PR01,PR02" \
        -i "pandas.Series.dt.freq GL08" \
        -i "pandas.Series.dt.microseconds SA01" \
        -i "pandas.Series.dt.month_name PR01,PR02" \
        -i "pandas.Series.dt.nanoseconds SA01" \
        -i "pandas.Series.dt.normalize PR01" \
        -i "pandas.Series.dt.round PR01,PR02" \
        -i "pandas.Series.dt.seconds SA01" \
        -i "pandas.Series.dt.strftime PR01,PR02" \
        -i "pandas.Series.dt.to_period PR01,PR02" \
        -i "pandas.Series.dt.total_seconds PR01" \
        -i "pandas.Series.dt.tz_convert PR01,PR02" \
        -i "pandas.Series.dt.tz_localize PR01,PR02" \
        -i "pandas.Series.dt.unit GL08" \
        -i "pandas.Series.pad PR01,SA01" \
        -i "pandas.Series.sparse.fill_value SA01" \
        -i "pandas.Series.sparse.from_coo PR07,SA01" \
        -i "pandas.Series.sparse.npoints SA01" \
        -i "pandas.Series.sparse.sp_values SA01" \
        -i "pandas.Timedelta.components SA01" \
        -i "pandas.Timedelta.max PR02" \
        -i "pandas.Timedelta.min PR02" \
        -i "pandas.Timedelta.resolution PR02" \
        -i "pandas.Timedelta.to_numpy PR01" \
        -i "pandas.Timedelta.to_timedelta64 SA01" \
        -i "pandas.Timedelta.total_seconds SA01" \
        -i "pandas.Timedelta.view SA01" \
        -i "pandas.TimedeltaIndex.components SA01" \
        -i "pandas.TimedeltaIndex.microseconds SA01" \
        -i "pandas.TimedeltaIndex.nanoseconds SA01" \
        -i "pandas.TimedeltaIndex.seconds SA01" \
        -i "pandas.TimedeltaIndex.to_pytimedelta RT03,SA01" \
        -i "pandas.Timestamp.max PR02" \
        -i "pandas.Timestamp.min PR02" \
        -i "pandas.Timestamp.nanosecond GL08" \
        -i "pandas.Timestamp.resolution PR02" \
        -i "pandas.Timestamp.tzinfo GL08" \
        -i "pandas.Timestamp.year GL08" \
        -i "pandas.api.extensions.ExtensionArray.interpolate PR01,SA01" \
        -i "pandas.api.types.is_bool PR01,SA01" \
        -i "pandas.api.types.is_categorical_dtype SA01" \
        -i "pandas.api.types.is_complex PR01,SA01" \
        -i "pandas.api.types.is_complex_dtype SA01" \
        -i "pandas.api.types.is_datetime64_dtype SA01" \
        -i "pandas.api.types.is_datetime64_ns_dtype SA01" \
        -i "pandas.api.types.is_datetime64tz_dtype SA01" \
        -i "pandas.api.types.is_dict_like PR07,SA01" \
        -i "pandas.api.types.is_extension_array_dtype SA01" \
        -i "pandas.api.types.is_file_like PR07,SA01" \
        -i "pandas.api.types.is_float PR01,SA01" \
        -i "pandas.api.types.is_float_dtype SA01" \
        -i "pandas.api.types.is_hashable PR01,RT03,SA01" \
        -i "pandas.api.types.is_int64_dtype SA01" \
        -i "pandas.api.types.is_integer PR01,SA01" \
        -i "pandas.api.types.is_integer_dtype SA01" \
        -i "pandas.api.types.is_interval_dtype SA01" \
        -i "pandas.api.types.is_iterator PR07,SA01" \
        -i "pandas.api.types.is_list_like SA01" \
        -i "pandas.api.types.is_named_tuple PR07,SA01" \
        -i "pandas.api.types.is_object_dtype SA01" \
        -i "pandas.api.types.is_re PR07,SA01" \
        -i "pandas.api.types.is_re_compilable PR07,SA01" \
        -i "pandas.api.types.pandas_dtype PR07,RT03,SA01" \
        -i "pandas.arrays.ArrowExtensionArray PR07,SA01" \
        -i "pandas.arrays.BooleanArray SA01" \
        -i "pandas.arrays.DatetimeArray SA01" \
        -i "pandas.arrays.FloatingArray SA01" \
        -i "pandas.arrays.IntegerArray SA01" \
        -i "pandas.arrays.IntervalArray.left SA01" \
        -i "pandas.arrays.IntervalArray.length SA01" \
        -i "pandas.arrays.IntervalArray.mid SA01" \
        -i "pandas.arrays.IntervalArray.right SA01" \
        -i "pandas.arrays.NumpyExtensionArray SA01" \
        -i "pandas.arrays.SparseArray PR07,SA01" \
        -i "pandas.arrays.TimedeltaArray PR07,SA01" \
        -i "pandas.core.groupby.DataFrameGroupBy.__iter__ RT03,SA01" \
        -i "pandas.core.groupby.DataFrameGroupBy.agg RT03" \
        -i "pandas.core.groupby.DataFrameGroupBy.aggregate RT03" \
        -i "pandas.core.groupby.DataFrameGroupBy.boxplot PR07,RT03,SA01" \
        -i "pandas.core.groupby.DataFrameGroupBy.filter SA01" \
        -i "pandas.core.groupby.DataFrameGroupBy.get_group RT03,SA01" \
        -i "pandas.core.groupby.DataFrameGroupBy.groups SA01" \
        -i "pandas.core.groupby.DataFrameGroupBy.hist RT03" \
        -i "pandas.core.groupby.DataFrameGroupBy.indices SA01" \
        -i "pandas.core.groupby.DataFrameGroupBy.max SA01" \
        -i "pandas.core.groupby.DataFrameGroupBy.min SA01" \
        -i "pandas.core.groupby.DataFrameGroupBy.nth PR02" \
        -i "pandas.core.groupby.DataFrameGroupBy.nunique SA01" \
        -i "pandas.core.groupby.DataFrameGroupBy.ohlc SA01" \
        -i "pandas.core.groupby.DataFrameGroupBy.plot PR02" \
        -i "pandas.core.groupby.DataFrameGroupBy.sem SA01" \
        -i "pandas.core.groupby.DataFrameGroupBy.sum SA01" \
        -i "pandas.core.groupby.SeriesGroupBy.__iter__ RT03,SA01" \
        -i "pandas.core.groupby.SeriesGroupBy.agg RT03" \
        -i "pandas.core.groupby.SeriesGroupBy.aggregate RT03" \
        -i "pandas.core.groupby.SeriesGroupBy.filter PR01,SA01" \
        -i "pandas.core.groupby.SeriesGroupBy.get_group RT03,SA01" \
        -i "pandas.core.groupby.SeriesGroupBy.groups SA01" \
        -i "pandas.core.groupby.SeriesGroupBy.indices SA01" \
        -i "pandas.core.groupby.SeriesGroupBy.is_monotonic_decreasing SA01" \
        -i "pandas.core.groupby.SeriesGroupBy.is_monotonic_increasing SA01" \
        -i "pandas.core.groupby.SeriesGroupBy.max SA01" \
        -i "pandas.core.groupby.SeriesGroupBy.min SA01" \
        -i "pandas.core.groupby.SeriesGroupBy.nth PR02" \
        -i "pandas.core.groupby.SeriesGroupBy.ohlc SA01" \
        -i "pandas.core.groupby.SeriesGroupBy.plot PR02" \
        -i "pandas.core.groupby.SeriesGroupBy.sem SA01" \
        -i "pandas.core.groupby.SeriesGroupBy.sum SA01" \
        -i "pandas.core.resample.Resampler.__iter__ RT03,SA01" \
        -i "pandas.core.resample.Resampler.ffill RT03" \
        -i "pandas.core.resample.Resampler.get_group RT03,SA01" \
        -i "pandas.core.resample.Resampler.groups SA01" \
        -i "pandas.core.resample.Resampler.indices SA01" \
        -i "pandas.core.resample.Resampler.max PR01,RT03,SA01" \
        -i "pandas.core.resample.Resampler.mean SA01" \
        -i "pandas.core.resample.Resampler.min PR01,RT03,SA01" \
        -i "pandas.core.resample.Resampler.ohlc SA01" \
        -i "pandas.core.resample.Resampler.prod SA01" \
        -i "pandas.core.resample.Resampler.quantile PR01,PR07" \
        -i "pandas.core.resample.Resampler.sem SA01" \
        -i "pandas.core.resample.Resampler.std SA01" \
        -i "pandas.core.resample.Resampler.sum SA01" \
        -i "pandas.core.resample.Resampler.transform PR01,RT03,SA01" \
        -i "pandas.core.resample.Resampler.var SA01" \
        -i "pandas.date_range RT03" \
        -i "pandas.errors.AttributeConflictWarning SA01" \
        -i "pandas.errors.CSSWarning SA01" \
        -i "pandas.errors.CategoricalConversionWarning SA01" \
        -i "pandas.errors.ChainedAssignmentError SA01" \
        -i "pandas.errors.ClosedFileError SA01" \
        -i "pandas.errors.DataError SA01" \
        -i "pandas.errors.DuplicateLabelError SA01" \
        -i "pandas.errors.EmptyDataError SA01" \
        -i "pandas.errors.IntCastingNaNError SA01" \
        -i "pandas.errors.InvalidIndexError SA01" \
        -i "pandas.errors.InvalidVersion SA01" \
        -i "pandas.errors.MergeError SA01" \
        -i "pandas.errors.NullFrequencyError SA01" \
        -i "pandas.errors.NumExprClobberingError SA01" \
        -i "pandas.errors.NumbaUtilError SA01" \
        -i "pandas.errors.OptionError SA01" \
        -i "pandas.errors.OutOfBoundsDatetime SA01" \
        -i "pandas.errors.OutOfBoundsTimedelta SA01" \
        -i "pandas.errors.PerformanceWarning SA01" \
        -i "pandas.errors.PossibleDataLossError SA01" \
        -i "pandas.errors.PossiblePrecisionLoss SA01" \
        -i "pandas.errors.SpecificationError SA01" \
        -i "pandas.errors.UndefinedVariableError PR01,SA01" \
        -i "pandas.errors.UnsortedIndexError SA01" \
        -i "pandas.errors.UnsupportedFunctionCall SA01" \
        -i "pandas.errors.ValueLabelTypeMismatch SA01" \
        -i "pandas.infer_freq SA01" \
        -i "pandas.io.json.build_table_schema PR07,RT03,SA01" \
        -i "pandas.io.stata.StataReader.data_label SA01" \
        -i "pandas.io.stata.StataReader.value_labels RT03,SA01" \
        -i "pandas.io.stata.StataReader.variable_labels RT03,SA01" \
        -i "pandas.io.stata.StataWriter.write_file SA01" \
        -i "pandas.json_normalize RT03,SA01" \
        -i "pandas.period_range RT03,SA01" \
        -i "pandas.plotting.andrews_curves RT03,SA01" \
        -i "pandas.plotting.lag_plot RT03,SA01" \
        -i "pandas.plotting.scatter_matrix PR07,SA01" \
        -i "pandas.set_eng_float_format RT03,SA01" \
        -i "pandas.testing.assert_extension_array_equal SA01" \
        -i "pandas.tseries.offsets.BDay PR02,SA01" \
        -i "pandas.tseries.offsets.BQuarterBegin.is_on_offset GL08" \
        -i "pandas.tseries.offsets.BQuarterBegin.n GL08" \
        -i "pandas.tseries.offsets.BQuarterBegin.normalize GL08" \
        -i "pandas.tseries.offsets.BQuarterBegin.rule_code GL08" \
        -i "pandas.tseries.offsets.BQuarterBegin.startingMonth GL08" \
        -i "pandas.tseries.offsets.BQuarterEnd.is_on_offset GL08" \
        -i "pandas.tseries.offsets.BQuarterEnd.n GL08" \
        -i "pandas.tseries.offsets.BQuarterEnd.normalize GL08" \
        -i "pandas.tseries.offsets.BQuarterEnd.rule_code GL08" \
        -i "pandas.tseries.offsets.BQuarterEnd.startingMonth GL08" \
        -i "pandas.tseries.offsets.BYearBegin.is_on_offset GL08" \
        -i "pandas.tseries.offsets.BYearBegin.month GL08" \
        -i "pandas.tseries.offsets.BYearBegin.n GL08" \
        -i "pandas.tseries.offsets.BYearBegin.normalize GL08" \
        -i "pandas.tseries.offsets.BYearEnd.is_on_offset GL08" \
        -i "pandas.tseries.offsets.BYearEnd.month GL08" \
        -i "pandas.tseries.offsets.BYearEnd.n GL08" \
        -i "pandas.tseries.offsets.BYearEnd.normalize GL08" \
        -i "pandas.tseries.offsets.BusinessDay PR02,SA01" \
        -i "pandas.tseries.offsets.BusinessDay.calendar GL08" \
        -i "pandas.tseries.offsets.BusinessDay.holidays GL08" \
        -i "pandas.tseries.offsets.BusinessDay.is_on_offset GL08" \
        -i "pandas.tseries.offsets.BusinessDay.n GL08" \
        -i "pandas.tseries.offsets.BusinessDay.normalize GL08" \
        -i "pandas.tseries.offsets.BusinessDay.weekmask GL08" \
        -i "pandas.tseries.offsets.BusinessHour PR02,SA01" \
        -i "pandas.tseries.offsets.BusinessHour.calendar GL08" \
        -i "pandas.tseries.offsets.BusinessHour.end GL08" \
        -i "pandas.tseries.offsets.BusinessHour.holidays GL08" \
        -i "pandas.tseries.offsets.BusinessHour.is_on_offset GL08" \
        -i "pandas.tseries.offsets.BusinessHour.n GL08" \
        -i "pandas.tseries.offsets.BusinessHour.normalize GL08" \
        -i "pandas.tseries.offsets.BusinessHour.start GL08" \
        -i "pandas.tseries.offsets.BusinessHour.weekmask GL08" \
        -i "pandas.tseries.offsets.BusinessMonthBegin.is_on_offset GL08" \
        -i "pandas.tseries.offsets.BusinessMonthBegin.n GL08" \
        -i "pandas.tseries.offsets.BusinessMonthBegin.normalize GL08" \
        -i "pandas.tseries.offsets.BusinessMonthEnd.is_on_offset GL08" \
        -i "pandas.tseries.offsets.BusinessMonthEnd.n GL08" \
        -i "pandas.tseries.offsets.BusinessMonthEnd.normalize GL08" \
        -i "pandas.tseries.offsets.CBMonthBegin PR02" \
        -i "pandas.tseries.offsets.CBMonthEnd PR02" \
        -i "pandas.tseries.offsets.CDay PR02,SA01" \
        -i "pandas.tseries.offsets.CustomBusinessDay PR02,SA01" \
        -i "pandas.tseries.offsets.CustomBusinessDay.calendar GL08" \
        -i "pandas.tseries.offsets.CustomBusinessDay.holidays GL08" \
        -i "pandas.tseries.offsets.CustomBusinessDay.is_on_offset GL08" \
        -i "pandas.tseries.offsets.CustomBusinessDay.n GL08" \
        -i "pandas.tseries.offsets.CustomBusinessDay.normalize GL08" \
        -i "pandas.tseries.offsets.CustomBusinessDay.weekmask GL08" \
        -i "pandas.tseries.offsets.CustomBusinessHour PR02,SA01" \
        -i "pandas.tseries.offsets.CustomBusinessHour.calendar GL08" \
        -i "pandas.tseries.offsets.CustomBusinessHour.end GL08" \
        -i "pandas.tseries.offsets.CustomBusinessHour.holidays GL08" \
        -i "pandas.tseries.offsets.CustomBusinessHour.is_on_offset GL08" \
        -i "pandas.tseries.offsets.CustomBusinessHour.n GL08" \
        -i "pandas.tseries.offsets.CustomBusinessHour.normalize GL08" \
        -i "pandas.tseries.offsets.CustomBusinessHour.start GL08" \
        -i "pandas.tseries.offsets.CustomBusinessHour.weekmask GL08" \
        -i "pandas.tseries.offsets.CustomBusinessMonthBegin PR02" \
        -i "pandas.tseries.offsets.CustomBusinessMonthBegin.calendar GL08" \
        -i "pandas.tseries.offsets.CustomBusinessMonthBegin.holidays GL08" \
        -i "pandas.tseries.offsets.CustomBusinessMonthBegin.is_on_offset SA01" \
        -i "pandas.tseries.offsets.CustomBusinessMonthBegin.m_offset GL08" \
        -i "pandas.tseries.offsets.CustomBusinessMonthBegin.n GL08" \
        -i "pandas.tseries.offsets.CustomBusinessMonthBegin.normalize GL08" \
        -i "pandas.tseries.offsets.CustomBusinessMonthBegin.weekmask GL08" \
        -i "pandas.tseries.offsets.CustomBusinessMonthEnd PR02" \
        -i "pandas.tseries.offsets.CustomBusinessMonthEnd.calendar GL08" \
        -i "pandas.tseries.offsets.CustomBusinessMonthEnd.holidays GL08" \
        -i "pandas.tseries.offsets.CustomBusinessMonthEnd.is_on_offset SA01" \
        -i "pandas.tseries.offsets.CustomBusinessMonthEnd.m_offset GL08" \
        -i "pandas.tseries.offsets.CustomBusinessMonthEnd.n GL08" \
        -i "pandas.tseries.offsets.CustomBusinessMonthEnd.normalize GL08" \
        -i "pandas.tseries.offsets.CustomBusinessMonthEnd.weekmask GL08" \
        -i "pandas.tseries.offsets.DateOffset.is_on_offset GL08" \
        -i "pandas.tseries.offsets.DateOffset.n GL08" \
        -i "pandas.tseries.offsets.DateOffset.normalize GL08" \
        -i "pandas.tseries.offsets.Day.is_on_offset GL08" \
        -i "pandas.tseries.offsets.Day.n GL08" \
        -i "pandas.tseries.offsets.Day.normalize GL08" \
        -i "pandas.tseries.offsets.Easter.is_on_offset GL08" \
        -i "pandas.tseries.offsets.Easter.n GL08" \
        -i "pandas.tseries.offsets.Easter.normalize GL08" \
        -i "pandas.tseries.offsets.FY5253.get_rule_code_suffix GL08" \
        -i "pandas.tseries.offsets.FY5253.get_year_end GL08" \
        -i "pandas.tseries.offsets.FY5253.is_on_offset GL08" \
        -i "pandas.tseries.offsets.FY5253.n GL08" \
        -i "pandas.tseries.offsets.FY5253.normalize GL08" \
        -i "pandas.tseries.offsets.FY5253.rule_code GL08" \
        -i "pandas.tseries.offsets.FY5253.startingMonth GL08" \
        -i "pandas.tseries.offsets.FY5253.variation GL08" \
        -i "pandas.tseries.offsets.FY5253.weekday GL08" \
        -i "pandas.tseries.offsets.FY5253Quarter.get_rule_code_suffix GL08" \
        -i "pandas.tseries.offsets.FY5253Quarter.get_weeks GL08" \
        -i "pandas.tseries.offsets.FY5253Quarter.is_on_offset GL08" \
        -i "pandas.tseries.offsets.FY5253Quarter.n GL08" \
        -i "pandas.tseries.offsets.FY5253Quarter.normalize GL08" \
        -i "pandas.tseries.offsets.FY5253Quarter.qtr_with_extra_week GL08" \
        -i "pandas.tseries.offsets.FY5253Quarter.rule_code GL08" \
        -i "pandas.tseries.offsets.FY5253Quarter.startingMonth GL08" \
        -i "pandas.tseries.offsets.FY5253Quarter.variation GL08" \
        -i "pandas.tseries.offsets.FY5253Quarter.weekday GL08" \
        -i "pandas.tseries.offsets.FY5253Quarter.year_has_extra_week GL08" \
        -i "pandas.tseries.offsets.Hour.is_on_offset GL08" \
        -i "pandas.tseries.offsets.Hour.n GL08" \
        -i "pandas.tseries.offsets.Hour.normalize GL08" \
        -i "pandas.tseries.offsets.LastWeekOfMonth SA01" \
        -i "pandas.tseries.offsets.LastWeekOfMonth.is_on_offset GL08" \
        -i "pandas.tseries.offsets.LastWeekOfMonth.n GL08" \
        -i "pandas.tseries.offsets.LastWeekOfMonth.normalize GL08" \
        -i "pandas.tseries.offsets.LastWeekOfMonth.week GL08" \
        -i "pandas.tseries.offsets.LastWeekOfMonth.weekday GL08" \
        -i "pandas.tseries.offsets.Micro.is_on_offset GL08" \
        -i "pandas.tseries.offsets.Micro.n GL08" \
        -i "pandas.tseries.offsets.Micro.normalize GL08" \
        -i "pandas.tseries.offsets.Milli.is_on_offset GL08" \
        -i "pandas.tseries.offsets.Milli.n GL08" \
        -i "pandas.tseries.offsets.Milli.normalize GL08" \
        -i "pandas.tseries.offsets.Minute.is_on_offset GL08" \
        -i "pandas.tseries.offsets.Minute.n GL08" \
        -i "pandas.tseries.offsets.Minute.normalize GL08" \
        -i "pandas.tseries.offsets.MonthBegin.is_on_offset GL08" \
        -i "pandas.tseries.offsets.MonthBegin.n GL08" \
        -i "pandas.tseries.offsets.MonthBegin.normalize GL08" \
        -i "pandas.tseries.offsets.MonthEnd.is_on_offset GL08" \
        -i "pandas.tseries.offsets.MonthEnd.n GL08" \
        -i "pandas.tseries.offsets.MonthEnd.normalize GL08" \
        -i "pandas.tseries.offsets.Nano.is_on_offset GL08" \
        -i "pandas.tseries.offsets.Nano.normalize GL08" \
        -i "pandas.tseries.offsets.Nano.n GL08" \
        -i "pandas.tseries.offsets.QuarterBegin.is_on_offset GL08" \
        -i "pandas.tseries.offsets.QuarterBegin.n GL08" \
        -i "pandas.tseries.offsets.QuarterBegin.normalize GL08" \
        -i "pandas.tseries.offsets.QuarterBegin.rule_code GL08" \
        -i "pandas.tseries.offsets.QuarterBegin.startingMonth GL08" \
        -i "pandas.tseries.offsets.QuarterEnd.is_on_offset GL08" \
        -i "pandas.tseries.offsets.QuarterEnd.n GL08" \
        -i "pandas.tseries.offsets.QuarterEnd.normalize GL08" \
        -i "pandas.tseries.offsets.QuarterEnd.rule_code GL08" \
        -i "pandas.tseries.offsets.QuarterEnd.startingMonth GL08" \
        -i "pandas.tseries.offsets.Second.is_on_offset GL08" \
        -i "pandas.tseries.offsets.Second.n GL08" \
        -i "pandas.tseries.offsets.Second.normalize GL08" \
        -i "pandas.tseries.offsets.SemiMonthBegin SA01" \
        -i "pandas.tseries.offsets.SemiMonthBegin.day_of_month GL08" \
        -i "pandas.tseries.offsets.SemiMonthBegin.is_on_offset GL08" \
        -i "pandas.tseries.offsets.SemiMonthBegin.n GL08" \
        -i "pandas.tseries.offsets.SemiMonthBegin.normalize GL08" \
        -i "pandas.tseries.offsets.SemiMonthBegin.rule_code GL08" \
        -i "pandas.tseries.offsets.SemiMonthEnd SA01" \
        -i "pandas.tseries.offsets.SemiMonthEnd.day_of_month GL08" \
        -i "pandas.tseries.offsets.SemiMonthEnd.is_on_offset GL08" \
        -i "pandas.tseries.offsets.SemiMonthEnd.n GL08" \
        -i "pandas.tseries.offsets.SemiMonthEnd.normalize GL08" \
        -i "pandas.tseries.offsets.SemiMonthEnd.rule_code GL08" \
        -i "pandas.tseries.offsets.Tick GL08" \
        -i "pandas.tseries.offsets.Tick.is_on_offset GL08" \
        -i "pandas.tseries.offsets.Tick.n GL08" \
        -i "pandas.tseries.offsets.Tick.normalize GL08" \
        -i "pandas.tseries.offsets.Week.is_on_offset GL08" \
        -i "pandas.tseries.offsets.Week.n GL08" \
        -i "pandas.tseries.offsets.Week.normalize GL08" \
        -i "pandas.tseries.offsets.Week.weekday GL08" \
        -i "pandas.tseries.offsets.WeekOfMonth SA01" \
        -i "pandas.tseries.offsets.WeekOfMonth.is_on_offset GL08" \
        -i "pandas.tseries.offsets.WeekOfMonth.n GL08" \
        -i "pandas.tseries.offsets.WeekOfMonth.normalize GL08" \
        -i "pandas.tseries.offsets.WeekOfMonth.week GL08" \
        -i "pandas.tseries.offsets.WeekOfMonth.weekday GL08" \
        -i "pandas.tseries.offsets.YearBegin.is_on_offset GL08" \
        -i "pandas.tseries.offsets.YearBegin.month GL08" \
        -i "pandas.tseries.offsets.YearBegin.n GL08" \
        -i "pandas.tseries.offsets.YearBegin.normalize GL08" \
        -i "pandas.tseries.offsets.YearEnd.is_on_offset GL08" \
        -i "pandas.tseries.offsets.YearEnd.month GL08" \
        -i "pandas.tseries.offsets.YearEnd.n GL08" \
        -i "pandas.tseries.offsets.YearEnd.normalize GL08" \
        -i "pandas.util.hash_pandas_object PR07,SA01" # There should be no backslash in the final line, please keep this comment in the last ignored function

    RET=$(($RET + $?)) ; echo $MSG "DONE"

fi

### DOCUMENTATION NOTEBOOKS ###
if [[ -z "$CHECK" || "$CHECK" == "notebooks" ]]; then

    MSG='Notebooks' ; echo $MSG
    jupyter nbconvert --execute $(find doc/source -name '*.ipynb') --to notebook
    RET=$(($RET + $?)) ; echo $MSG "DONE"

fi

### SINGLE-PAGE DOCS ###
if [[ -z "$CHECK" || "$CHECK" == "single-docs" ]]; then
    python doc/make.py --warnings-are-errors --no-browser --single pandas.Series.value_counts
    python doc/make.py --warnings-are-errors --no-browser --single pandas.Series.str.split
fi

exit $RET
