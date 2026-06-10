# PowerLanguage Keywords Index

Index of every PowerLanguage keyword grouped by the 40 categories from MultiCharts's help system. For full per-keyword documentation, open `details/<Category>/<Keyword>.md`.

## AccountsPositions

| Keyword | Signature |
|---|---|
| `GetAccount` | `GetAccount(AccountLoc)` |
| `GetAccountID` | `GetAccountID()` |
| `GetNumAccounts` | `GetNumAccounts` |
| `GetNumPositions` | `GetNumPositions(Account)` |
| `GetPositionAveragePrice` | `GetPositionAveragePrice(Symbol, Account)` |
| `GetPositionBrokerSymbol` | `GetPositionBrokerSymbol(Account, PositionLoc)` |
| `GetPositionOpenPL` | `GetPositionOpenPL(Symbol, Account)` |
| `GetPositionQuantity` | `GetPositionQuantity(Symbol, Account)` |
| `GetPositionSymbol` | `GetPositionSymbol(Account, PositionLoc)` |
| `GetPositionTotalCost` | `GetPositionTotalCost(Symbol, Account)` |
| `GetRTAccountEquity` | `GetRTAccountEquity(Account)` |
| `GetRTAccountNetWorth` | `GetRTAccountNetWorth(Account)` |
| `GetRTUnrealizedPL` | `GetRTUnrealizedPL(Account)` |
| `InitialCapital` | `InitialCapital` |

## Alerts

| Keyword | Signature |
|---|---|
| `Alert` | `Alert` |
| `AlertEnabled` | `AlertEnabled` |
| `AlertEx` | `AlertEx(text[,bgColor[,txtColor]]);` |
| `Cancel Alert` | `Cancel Alert` |
| `CheckAlert` | `CheckAlert` |

## Arrow_Drawing

| Keyword | Signature |
|---|---|
| `Arw_Anchor_to_Bars` | `Arw_Anchor_to_Bars(ArrowID,LogicalExpression)` |
| `Arw_Delete` | `Arw_Delete(ObjectID)` |
| `Arw_Get_Anchor_to_Bars` | `Arw_Get_Anchor_to_Bars(ArrowID)` |
| `Arw_GetActive` | `Arw_GetActive` |
| `Arw_GetBarNumber` | `Arw_GetBarNumber(ref)` |
| `Arw_GetColor` | `Arw_GetColor(ObjectID)` |
| `Arw_GetDate` | `Arw_GetDate(ObjectID)` |
| `Arw_GetDirection` | `Arw_GetDirection(ObjectID)` |
| `Arw_GetFirst` | `Arw_GetFirst(Origin)` |
| `Arw_GetLock` | `Arw_GetLock(ArrowID)` |
| `Arw_GetNext` | `Arw_GetNext(ObjectID,Origin)` |
| `Arw_GetSize` | `Arw_GetSize(ObjectID)` |
| `Arw_GetStyle` | `Arw_GetStyle(ObjectID)` |
| `Arw_GetText` | `Arw_GetText(ObjectID)` |
| `Arw_GetTextAttribute` | `Arw_GetTextAttribute(ObjectID,Attribute)` |
| `Arw_GetTextBGColor` | `Arw_GetTextBGColor(ObjectID)` |
| `Arw_GetTextColor` | `Arw_GetTextColor(ObjectID)` |
| `Arw_GetTextFontName` | `Arw_GetTextFontName(ObjectID)` |
| `Arw_GetTextSize` | `Arw_GetTextSize(ObjectID)` |
| `Arw_GetTime` | `Arw_GetTime(ObjectID)` |
| `Arw_GetTime_DT` | `Arw_GetTime_DT(ObjectID)` |
| `Arw_GetTime_s` | `Arw_GetTime_s(ObjectID)` |
| `Arw_GetVal` | `Arw_GetVal(ObjectID)` |
| `Arw_Lock` | `Arw_Lock(ArrowID,LogicalExpression)` |
| `Arw_New` | `Arw_New (BarDate, BarTime, PriceValue, Direction) Parameters` |
| `Arw_New_BN` | `Arw_New_BN (BarNumber, PriceValue, Direction) Parameters` |
| `Arw_New_DT` | `Arw_New_DT (Bar_DateTime, PriceValue, Direction) Parameters` |
| `Arw_New_s` | `Arw_New_s (BarDate, BarTime_s, PriceValue, Direction) Parameters` |
| `Arw_New_self` | `Arw_New_self (BarDate, BarTime, PriceValue, Direction) Parameters` |
| `ARW_New_Self_BN` | `ARW_New_Self_BN(BarNumber, PriceValue, Direction)` |
| `Arw_New_Self_DT` | `Arw_New_Self_DT (Bar_DateTime, PriceValue, Direction) Parameters` |
| `Arw_New_self_s` | `Arw_New_self_s (BarDate, BarTime_s, PriceValue, Direction) Parameters` |
| `Arw_SetBarNumber` | `Arw_SetBarNumber(ref,Barnumber)` |
| `Arw_SetColor` | `Arw_SetColor(ObjectID,ArrowColor) Parameters` |
| `Arw_SetLocation` | `Arw_SetLocation (ObjectID, BarDate, BarTime, PriceValue) Parameters` |
| `Arw_SetLocation_BN` | `Arw_SetLocation_BN (ObjectID, BarNumber, PriceValue) Parameters` |
| `Arw_SetLocation_DT` | `Arw_SetLocation_DT (ObjectID, Bar_DateTime, PriceValue) Parameters` |
| `Arw_SetLocation_s` | `Arw_SetLocation_s (ObjectID, BarDate, BarTime_s, PriceValue) Parameters` |
| `Arw_SetSize` | `Arw_SetSize(ObjectID,ArrowSize)` |
| `Arw_SetStyle` | `Arw_SetStyle(ObjectID,ArrowStyle)` |
| `Arw_SetText` | `Arw_SetText(ObjectID,"Text")` |
| `Arw_SetTextAttribute` | `Arw_SetTextAttribute(ObjectID,Attribute,LogicalExpression) Parameters` |
| `Arw_SetTextBGColor` | `Arw_SetTextBGColor(ObjectID,TextBGColor) Parameters` |
| `Arw_SetTextColor` | `Arw_SetTextColor(ObjectID,TextColor) Parameters` |
| `Arw_SetTextFontName` | `Arw_SetTextFontName(ObjectID,"FontName")` |
| `Arw_SetTextSize` | `Arw_SetTextSize(ObjectID,FontSize)` |
| `MC_Arw_GetActive` | `MC_Arw_GetActive` |

## Attributes

| Keyword | Signature |
|---|---|
| `AllowSendOrdersAlways` | `[AllowSendOrdersAlways = LogicalValue]` |
| `AllowSendOrdersOnBrokerPositionChange` | `[AllowSendOrdersOnBrokerPositionChange = LogicalValue]` |
| `AllowSendOrdersOnMouseEvents` | `[AllowSendOrdersOnMouseEvents = LogicalValue]` |
| `AllowSendOrdersOnOrderFilled` | `[AllowSendOrdersOnOrderFilled = LogicalValue]` |
| `AllowSendOrdersOnOrderReject` | `[AllowSendOrdersOnOrderReject = LogicalValue]` |
| `AllowSendOrdersOnPortfolioCloseButton` | `[AllowSendOrdersOnPortfolioCloseButton = LogicalValue]` |
| `AllowSendOrdersOnTick` | `[AllowSendOrdersOnTick = LogicalValue]` |
| `AllowSendOrdersOnTimer` | `[AllowSendOrdersOnTimer = LogicalValue]` |
| `IntraBarOrderGeneration` | `[IntrabarOrderGeneration = LogicalValue]` |
| `LegacyColorValue` | `[LegacyColorValue = LogicalValue]` |
| `ProcessMouseEvents` | `[ProcessMouseEvents = LogicalValue]` |
| `RecoverDrawings` | `[RecoverDrawings = LogicalValue]` |
| `SameExitFromOneEntryOnce` | `[SameExitFromOneEntryOnce = LogicalValue]` |

## Colors

| Keyword | Signature |
|---|---|
| `ARGB` | `ARGB (Alpha,Red,Green,Blue)` |
| `Black` | `Black` |
| `Blue` | `Blue` |
| `Cyan` | `Cyan` |
| `DarkBlue` | `DarkBlue` |
| `DarkBrown` | `DarkBrown` |
| `DarkCyan` | `DarkCyan` |
| `DarkGray` | `DarkGray` |
| `DarkGreen` | `DarkGreen` |
| `DarkMagenta` | `DarkMagenta` |
| `DarkRed` | `DarkRed` |
| `DarkYellow` | `DarkYellow` |
| `GetAValue` | `GetAValue(BigARGBValue)` |
| `GetBValue` | `GetBValue(BigRGBValue)` |
| `GetGValue` | `GetGValue(BigRGBValue)` |
| `GetRValue` | `GetRValue(BigRGBValue)` |
| `GradientColor` | `GradientColor(Value,Min,Max,StartColor,EndColor)` |
| `Green` | `Green` |
| `LegacyColorToRGB` | `LegacyColorToRGB(LegacyColorValue)` |
| `LightGray` | `LightGray` |
| `Magenta` | `Magenta` |
| `Red` | `Red` |
| `RGB` | `RGB (Red,Green,Blue)` |
| `RGBToLegacyColor` | `RGBToLegacyColor(RGBColorValue)` |
| `Transparent` | `Transparent` |
| `White` | `White` |
| `Yellow` | `Yellow` |

## Comparison_and_Loops

| Keyword | Signature |
|---|---|
| `Above` | `E1 Cross Above E2` |
| `And` | `E1 And E2` |
| `Begin` | `See official docs for signature details.` |
| `Below` | `E1 Cross Below E2` |
| `Break` | `Break;` |
| `case` | `See in example` |
| `Cross` | `E1 Cross Direction E2` |
| `Crosses` | `` |
| `DownTo` | `See official docs for signature details.` |
| `Else` | `If E Then I1 Else I2` |
| `End` | `See official docs for signature details.` |
| `False` | `False` |
| `For` | `See official docs for signature details.` |
| `If` | `If E Then I1 Else I2` |
| `Not` | `` |
| `Or` | `E1 Or E2 Where: E - true/false expressions` |
| `Over` | `` |
| `switch` | `switch expr begin` |
| `Then` | `See official docs for signature details.` |
| `To` | `See official docs for signature details.` |
| `True` | `True` |
| `Under` | `` |
| `While` | `See official docs for signature details.` |

## Currency_Codes

| Keyword | Signature |
|---|---|
| `AUD` | `AUD` |
| `CAD` | `CAD` |
| `CHF` | `CHF` |
| `Convert_Currency` | `Convert_Currency(DateTime, SrcCurrency, DstCurrency, SrcMoney);` |
| `CurrencyCodeToStr` | `CurrencyCodeToStr(CurrencyCode)` |
| `EUR` | `EUR` |
| `GBP` | `GBP` |
| `HKD` | `HKD` |
| `JPY` | `JPY` |
| `NOK` | `NOK` |
| `None` | `None` |
| `NZD` | `NZD` |
| `Portfolio_CurrencyCode` | `Portfolio_CurrencyCode` |
| `SEK` | `SEK` |
| `SGD` | `SGD` |
| `StrategyCurrencyCode` | `StrategyCurrencyCode` |
| `SymbolCurrencyCode` | `SymbolCurrencyCode` |
| `TRY_` | `TRY_` |
| `USD` | `USD` |
| `ZAR` | `ZAR` |

## Data_Information_General

| Keyword | Signature |
|---|---|
| `Ago` | `N Bars Ago` |
| `Bar` | `Bar` |
| `BarInterval` | `BarInterval` |
| `Bars` | `` |
| `BarStatus` | `BarStatus(DataNum)` |
| `BarType` | `See official docs for signature details.` |
| `BarType_ex` | `See official docs for signature details.` |
| `BarType_uid` | `See official docs for signature details.` |
| `BigPointValue` | `BigPointValue` |
| `BoxSize` | `BoxSize FormatString", DateTime)--> Parameters` |
| `C` | `` |
| `Call` | `Call` |
| `Category` | `Category` |
| `Close` | `Close` |
| `CurrentBar` | `CurrentBar` |
| `D` | `` |
| `DailyLimit` | `` |
| `Data` | `DataN` |
| `DataCompression` | `` |
| `Date` | `Date` |
| `DateTime` | `DateTime` |
| `DateTime bar update` | `datetime_bar_update` |
| `Day` | `` |
| `Days` | `` |
| `DeltaType` | `DeltaType The following values are returned:` |
| `DownTicks` | `DownTicks` |
| `ExpirationDate` | `ExpirationDate` |
| `ExpirationDateFromVendor` | `ExpirationDateFromVendor` |
| `GetExchangeName` | `GetExchangeName` |
| `GetRTSymbolName` | `GetRTSymbolName` |
| `GetSymbolName` | `GetSymbolName` |
| `H` | `` |
| `High` | `High` |
| `I` | `` |
| `IntervalType` | `IntervalType` |
| `IntervalType_ex` | `IntervalType_ex` |
| `L` | `` |
| `Low` | `Low` |
| `MinMove` | `MinMove` |
| `Next` | `Next Bar` |
| `O` | `` |
| `Open` | `Open` |
| `OpenInt` | `OpenInt` |
| `OptionType` | `OptionType` |
| `Point` | `Point` |
| `Points` | `` |
| `PointValue` | `PointValue` |
| `PriceScale` | `PriceScale` |
| `Put` | `Put` |
| `RevSize` | `StringToTime("hh:mm:ss tt")` |
| `ScrollToBar` | `ScrollToBar (int DataN, int BarN)` |
| `SessionLastBar` | `SessionLastBar` |
| `Strike` | `Strike` |
| `Symbol_Close` | `Symbol_Close` |
| `Symbol_CurrentBar` | `Symbol_CurrentBar` |
| `Symbol_Date` | `Symbol_Date` |
| `Symbol_DownTicks` | `Symbol_DownTicks` |
| `Symbol_High` | `Symbol_High` |
| `Symbol_Length` | `Symbol_Length` |
| `Symbol_Low` | `Symbol_Low` |
| `Symbol_Open` | `Symbol_Open` |
| `Symbol_OpenInt` | `Symbol_OpenInt` |
| `Symbol_TickID` | `Symbol_TickID` |
| `Symbol_Ticks` | `Symbol_Ticks` |
| `Symbol_Time` | `Symbol_Time` |
| `Symbol_Time_S` | `Symbol_Time_S` |
| `Symbol_UpTicks` | `Symbol_UpTicks` |
| `Symbol_Volume` | `Symbol_Volume` |
| `T` | `` |
| `This` | `This Bar` |
| `TickID` | `TickID` |
| `Ticks` | `Ticks` |
| `Time` | `Time` |
| `Time_s` | `Time_s` |
| `Today` | `` |
| `UpTicks` | `UpTicks` |
| `V` | `` |
| `Volume` | `Volume` |
| `Yesterday` | `` |

## Date_and_Time_routines

| Keyword | Signature |
|---|---|
| `calcdatetime` | `calcdatetime` |
| `ComputerDateTime` | `ComputerDateTime` |
| `CurrentDate` | `CurrentDate` |
| `CurrentTime` | `CurrentTime` |
| `CurrentTime_s` | `CurrentTime_s` |
| `DateTime2ELTime` | `DateTime2ELTime(DateTime)` |
| `DateTime2ELTime_s` | `DateTime2ELTime_s (DateTime)` |
| `DateTimeToString` | `DateTimeToString (DateTime)` |
| `DateTimeToString_Ms` | `DateTimeToString_Ms(DT)` |
| `DateToJulian` | `DateToJulian(YYYMMdd)` |
| `DateToString` | `DateToString(DateTime)` |
| `DayFromDateTime` | `DayFromDateTime(DateTime)` |
| `DayOfMonth` | `DayOfMonth(YYYMMdd)` |
| `DayOfWeek` | `DayOfWeek(YYYMMdd)` |
| `DayOfWeekFromDateTime` | `DayOfWeekFromDateTime(DateTime)` |
| `El_DateStr` | `El_DateStr(dd, MM, yyyy)` |
| `El_DateToDateTime` | `` |
| `EL_TimeToDateTime` | `` |
| `EL_TimeToDateTime_s` | `` |
| `ELDateToDateTime` | `ELDateToDateTime(YYYMMdd)` |
| `ELTimeToDateTime` | `ELTimeToDateTime(HHmm)` |
| `ELTimeToDateTime_s` | `ELTimeToDateTime_s(HHmmss)` |
| `EncodeDate` | `EncodeDate(yy,MM,dd)` |
| `EncodeTime` | `EncodeTime(HH,mm,ss,mmm)` |
| `FormatDate` | `FormatDate("FormatString", DateTime) Parameters` |
| `FormatTime` | `FormatTime("FormatString", DateTime) Parameters` |
| `Friday` | `Friday` |
| `GetTotalMilliseconds` | `GetTotalMilliseconds(datetime)` |
| `HoursFromDateTime` | `HoursFromDateTime(DateTime)` |
| `IncMonth` | `IncMonth(JulianDate,M)` |
| `JulianToDate` | `JulianToDate(JulianDate)` |
| `LastCalcDateTime` | `LastCalcDateTime` |
| `LastCalcJDate` | `LastCalcJDate` |
| `LastCalcMMTime` | `LastCalcMMTime` |
| `LastCalcmSTime` | `LastCalcmSTime` |
| `LastCalcSSTime` | `LastCalcSSTime` |
| `MilliSecondsFromDateTime` | `MilliSecondsFromDateTime(DT)` |
| `MinutesFromDateTime` | `MinutesFromDateTime(DateTime)` |
| `Monday` | `Monday` |
| `Month` | `Month(YYYMMdd)` |
| `MonthFromDateTime` | `MonthFromDateTime(DateTime)` |
| `Saturday` | `Saturday` |
| `SecondsFromDateTime` | `SecondsFromDateTime(DateTime)` |
| `StringToDate` | `StringToDate("MM/dd/yy")` |
| `StringToDateTime` | `StringToDateTime("MM/dd/yy hh:mm:ss tt")` |
| `StringToDTFormatted` | `StringToDTFormatted("DateTimeString", "FormatString")` |
| `StringToTime` | `StringToTime("hh:mm:ss tt")` |
| `Sunday` | `Sunday` |
| `Thursday` | `Thursday` |
| `Time_s2Time` | `Time_s2Time(HHmmss)` |
| `Time2Time_s` | `Time2Time_s(HHmm)` |
| `TimeToString` | `TimeToString(DateTime)` |
| `TimeToString_ms` | `TimeToString_ms(DateTime)` |
| `Tuesday` | `Tuesday` |
| `updatedatetime` | `updatedatetime` |
| `Wednesday` | `Wednesday` |
| `Year` | `Year(YYYMMdd)` |
| `YearFromDateTime` | `YearFromDateTime(DateTime)` |

## Declaration

| Keyword | Signature |
|---|---|
| `Array` | `Array:IntraBarPersist>ArrayName1[D1,D2,D3,etc.](InitialValue1,DataN>), IntraBarPersist>ArrayName2[D1,D2,D3,etc.](InitialValue2,DataN>),etc.` |
| `Arrays` | `` |
| `Input` | `Input: InputName1(DefaultValue1), InputName2(DefaultValue2), etc.` |
| `Inputs` | `` |
| `IntraBarPersist` | `Declaration:[IntraBarPersist]Name(InitialValue1)` |
| `Numeric` | `Input:InputName(Numeric)` |
| `NumericArray` | `Input:InputName[M1,M2,M3,etc.](NumericArray) Parameters` |
| `NumericArrayRef` | `Input:InputName[M1,M2,M3,etc.](NumericArrayRef) Parameters` |
| `NumericRef` | `Input:InputName(NumericRef)` |
| `NumericSeries` | `Input:InputName(NumericSeries)` |
| `NumericSimple` | `Input:InputName(NumericSimple)` |
| `RecalcPersist` | `Declaration:[RecalcPersist]Name(InitialValue1)` |
| `String` | `Input:InputName(String)` |
| `StringArray` | `` |
| `StringArrayRef` | `Input:InputName[M1,M2,M3,etc.](StringArrayRef) Parameters` |
| `StringRef` | `Input:InputName(StringRef)` |
| `StringSeries` | `Input:InputName(StringSeries)` |
| `StringSimple` | `Input:InputName(StringSimple)` |
| `TrueFalse` | `Input:InputName(TrueFalse)` |
| `TrueFalseArray` | `Input:InputName[M1,M2,M3,etc.](TrueFalseArray) Parameters` |
| `TrueFalseArrayRef` | `Input:InputName[M1,M2,M3,etc.](TrueFalseArrayRef) Parameters` |
| `TrueFalseRef` | `Input:InputName(TrueFalseRef)` |
| `TrueFalseSeries` | `Input:InputName(TrueFalseSeries)` |
| `TrueFalseSimple` | `Input:InputName(TrueFalseSimple)` |
| `Var` | `` |
| `Variable` | `Variable:[IntraBarPersist]VariableName1(InitialValue1[,DataN]), [IntraBarPersist]VariableName2(InitialValue2[,DataN]),etc.` |
| `Variables` | `` |
| `Vars` | `` |

## DLL_Calling

| Keyword | Signature |
|---|---|
| `#Events` | `` |
| `ArraySize` | `` |
| `ArrayStartAddr` | `` |
| `Bool` | `` |
| `Byte` | `` |
| `Char` | `` |
| `DefineDLLFunc` | `` |
| `Double` | `` |
| `DWORD` | `` |
| `External` | `` |
| `Float` | `` |
| `iEasyLanguageObject` | `` |
| `Int` | `` |
| `Int64` | `` |
| `Long` | `` |
| `LPBool` | `` |
| `LPByte` | `` |
| `LPDouble` | `` |
| `LPDWORD` | `` |
| `LPFloat` | `` |
| `LPInt` | `` |
| `LPLong` | `` |
| `LPSTR` | `` |
| `LPWORD` | `` |
| `Method` | `` |
| `OnCreate` | `` |
| `OnDestroy` | `` |
| `Self` | `` |
| `ThreadSafe` | `ThreadSafe` |
| `Unsigned` | `` |
| `VarSize` | `` |
| `VarStartAddr` | `` |
| `Void` | `` |
| `WORD` | `` |

## DOM

| Keyword | Signature |
|---|---|
| `DOM_AskPrice` | `DOM_AskPrice(num) [Data(N)]` |
| `DOM_AsksCount` | `DOM_AsksCount [Data(N)]` |
| `DOM_AskSize` | `DOM_AskSize(num) [Data(N)]` |
| `DOM_BidPrice` | `DOM_BidPrice(num) [Data(N)]` |
| `DOM_BidsCount` | `DOM_BidsCount [Data(N)]` |
| `DOM_BidSize` | `DOM_BidSize(num) [Data(N)]` |
| `DOM_IsConnected` | `DOM_IsConnected` |

## Dynamic_Arrays

| Keyword | Signature |
|---|---|
| `Array_Compare` | `Array_Compare(SourceArray,SourceIndex,DestinationArray,DestinationIndex,NumberOfElements)` |
| `Array_Contains` | `Array_Contains(ArrayName,Value)` |
| `Array_Copy` | `Array_Copy(SourceArray,SourceIndex,DestinationArray,DestinationIndex,NumberOfElements)` |
| `Array_GetBooleanValue` | `Array_GetBooleanValue` |
| `Array_GetFloatValue` | `Array_GetFloatValue` |
| `Array_GetIntegerValue` | `Array_GetIntegerValue` |
| `Array_GetMaxIndex` | `Array_GetMaxIndex(ArrayName)` |
| `Array_GetStringValue` | `Array_GetStringValue` |
| `Array_GetType` | `Array_GetType(ArrayName)` |
| `Array_IndexOf` | `Array_IndexOf(ArrayName,Value)` |
| `Array_SetBooleanValue` | `Array_SetBooleanValue` |
| `Array_SetFloatValue` | `Array_SetFloatValue` |
| `Array_SetIntegerValue` | `Array_SetIntegerValue` |
| `Array_SetMaxIndex` | `Array_SetMaxIndex(ArrayName,MaxIndex)` |
| `Array_SetStringValue` | `Array_SetStringValue` |
| `Array_SetValRange` | `Array_SetValRange(ArrayName,StartIndex,EndIndex,Value)` |
| `Array_Sort` | `Array_Sort(ArrayName,StartIndex,EndIndex,SortOrder)` |
| `Array_Sum` | `Array_Sum(ArrayName,StartIndex,EndIndex)` |
| `Fill_Array` | `Fill_Array(ArrayName,Value)` |

## Environment_Information

| Keyword | Signature |
|---|---|
| `BaseDataNumber` | `BaseDataNumber` |
| `CurrentDataNumber` | `CurrentDataNumber` |
| `ExecOffset` | `ExecOffset` |
| `GetAppInfo` | `GetAppInfo(Attribute) Parameters` |
| `GetCDRomDrive` | `GetCDRomDrive` |
| `GetCountry` | `GetCountry` |
| `GetCurrency` | `GetCurrency` |
| `getTPOinfo` | `getTPOinfo(style),` |
| `GetUserID` | `GetUserID` |
| `GetUserName` | `GetUserName` |
| `Is64BitOperatingSystem` | `Is64BitOperatingSystem` |
| `Is64BitProcess` | `Is64BitProcess` |
| `MaxBarsBack` | `MaxBarsBack` |
| `MaxBarsForward` | `MaxBarsForward` |
| `SetMaxBarsBack` | `SetMaxBarsBack(BarsBack)` |

## Execution_Control

| Keyword | Signature |
|---|---|
| `#Return` | `#Return;` |
| `Abort` | `Abort` |
| `CommandLine` | `CommandLine("Expression")` |
| `fpcExactAccuracy` | `SetFPCompareAccuracy(fpcExactAccuracy)` |
| `fpcHighAccuracy` | `SetFPCompareAccuracy(fpcHighAccuracy)` |
| `fpcLowAccuracy` | `SetFPCompareAccuracy(fpcLowAccuracy)` |
| `fpcMedAccuracy` | `SetFPCompareAccuracy(fpcMedAccuracy)` |
| `fpcVeryHighAccuracy` | `SetFPCompareAccuracy(fpcVeryHighAccuracy)` |
| `fpcVeryLowAccuracy` | `SetFPCompareAccuracy(fpcVeryLowAccuracy)` |
| `RaiseRunTimeError` | `RaiseRunTimeError("Message")` |
| `RecalcLastBarAfter` | `` |
| `ReCalculate` | `ReCalculate` |
| `SetFPCompareAccuracy` | `SetFPCompareAccuracy(Accuracy) Parameters` |
| `VerifyLicense` | `VerifyLicense("Study_Name", "Developer_ID")` |

## ExpertCommentary

| Keyword | Signature |
|---|---|
| `#BeginCmtry` | `#BeginCmtry` |
| `AtCommentaryBar` | `AtCommentaryBar` |
| `CheckCommentary` | `CheckCommentary` |
| `Commentary` | `Commentary ("My Expression");` |
| `CommentaryCL` | `CommentaryCL ("My Expression");` |
| `CommentaryEnabled` | `CommentaryEnabled` |

## Math_and_Trig

| Keyword | Signature |
|---|---|
| `AbsValue` | `AbsValue(Value)` |
| `ArcTangent` | `ArcTangent(Value)` |
| `AvgList` | `AvgList(Value1,Value2,Value3, etc.)` |
| `Ceiling` | `Ceiling(Value)` |
| `Cosine` | `Cosine(Value)` |
| `Cotangent` | `Cotangent(Value)` |
| `ExpValue` | `ExpValue(Value)` |
| `Floor` | `Floor(Value)` |
| `FracPortion` | `FracPortion(Value)` |
| `IntPortion` | `IntPortion(Value)` |
| `Log` | `Log(Value)` |
| `MaxList` | `MaxList(Value1,Value2,Value3, etc.)` |
| `MaxList2` | `MaxList2(Value1,Value2,Value3, etc.)` |
| `MinList` | `MinList(Value1,Value2,Value3, etc.)` |
| `MinList2` | `MinList2(Value1,Value2,Value3, etc.)` |
| `Mod` | `Mod(Dividend,Divisor)` |
| `Neg` | `Neg(Value)` |
| `NthMaxList` | `NthMaxList(N,Value1,Value2,Value3, etc.)` |
| `NthMinList` | `NthMinList(N,Value1,Value2,Value3, etc.)` |
| `Pos` | `` |
| `Power` | `Power(Base,Exponent)` |
| `Random` | `Random(Value)` |
| `Round` | `Round(Value,Precision)` |
| `Sign` | `Sign(Value)` |
| `Sine` | `Sine(Value)` |
| `Square` | `Square(Value)` |
| `SquareRoot` | `SquareRoot(Value)` |
| `SumList` | `SumList(Value1,Value2,Value3, etc.)` |
| `Tangent` | `Tangent(Value)` |

## Miscellaneous_keywords

| Keyword | Signature |
|---|---|
| `Ago` | `N Bars Ago` |
| `Bar` | `Bar` |
| `Bars` | `` |
| `Contract` | `` |
| `Contracts` | `TradeSize Contracts` |
| `Market` | `At Market` |
| `Next` | `Next Bar` |
| `This` | `This Bar` |
| `Today` | `` |
| `Yesterday` | `` |

## MouseClickEvents

| Keyword | Signature |
|---|---|
| `MouseClickBarNumber` | `MouseClickBarNumber` |
| `MouseClickCtrlPressed` | `MouseClickCtrlPressed` |
| `MouseClickDataNumber` | `MouseClickDataNumber` |
| `MouseClickDateTime` | `MouseClickDateTime` |
| `MouseClickPrice` | `MouseClickPrice` |
| `MouseClickShiftPressed` | `MouseClickShiftPressed` |

## Multimedia

| Keyword | Signature |
|---|---|
| `PlaySound` | `` |

## Output

| Keyword | Signature |
|---|---|
| `ClearDebug` | `ClearDebug` |
| `ClearPrintLog` | `` |
| `File` | `File("PathFilename")` |
| `FileAppend` | `FileAppend("PathFilename","StringExpression")` |
| `FileClose` | `FileClose("PathFilename")` |
| `FileDelete` | `FileDelete("PathFilename")` |
| `MessageLog` | `MessageLog(Expression1,Expression2,etc.) Parameters` |
| `Print` | `See official docs for signature details.` |

## Plotting

| Keyword | Signature |
|---|---|
| `Default` | `Default` |
| `GetBackgroundColor` | `GetBackgroundColor` |
| `GetPlotBGColor` | `GetPlotBGColor(PlotNum)` |
| `GetPlotColor` | `GetPlotColor(PlotNumber)` |
| `getplotstyle` | `getplotstyle(PlotNumber)` |
| `GetPlotWidth` | `GetPlotWidth(PlotNumber)` |
| `I_getplotvalue` | `i_getplotvalue(index)` |
| `I_setplotvalue` | `i_setplotvalue(index,value)` |
| `NoPlot` | `NoPlot(PlotNumber)` |
| `Plot` | `Numerical: PlotN[Offset](Expression [,"PlotName"[,PlotColor [,Scanner Cell Background Color [,LineWidth ]]]])` |
| `PlotPaintBar` | `See official docs for signature details.` |
| `PlotPB` | `` |
| `SetPlotBGColor` | `SetPlotBGColor(PlotNumber,PlotColor)` |
| `SetPlotColor` | `SetPlotColor(PlotNumber,PlotColor)` |
| `setplotstyle` | `setplotstyle(PlotNumber,LineStyle)` |
| `SetPlotWidth` | `SetPlotWidth(PlotNumber,LineWidth)` |

## Portfolio_Money_Management

| Keyword | Signature |
|---|---|
| `pmm_get_global_named_num` | `pmm_get_global_named_num(VariableName)` |
| `pmm_get_global_named_str` | `pmm_get_global_named_str(VariableName)` |
| `pmm_get_my_index` | `pmm_get_my_index` |
| `pmm_get_my_named_num` | `pmm_get_my_named_num(VariableName)` |
| `pmm_get_my_named_str` | `pmm_get_my_named_str(VariableName)` |
| `pmm_set_global_named_num` | `pmm_set_global_named_num(VariableName, VariableValue)` |
| `pmm_set_global_named_str` | `pmm_set_global_named_str(VariableName, VariableValue)` |
| `pmm_set_my_named_num` | `pmm_set_my_named_num(VariableName, VariableValue)` |
| `pmm_set_my_named_str` | `pmm_set_my_named_str(VariableName, VariableValue)` |
| `pmm_set_my_status` | `pmm_set_my_status(Status)` |
| `pmms_get_strategy_named_num` | `pmms_get_strategy_named_num(StrategyIndex, VariableName)` |
| `pmms_get_strategy_named_str` | `pmms_get_strategy_named_str(StrategyIndex, VariableName)` |
| `pmms_set_strategy_named_num` | `pmms_set_strategy_named_num(StrategyIndex, VariableName, VariableValue)` |
| `pmms_set_strategy_named_str` | `pmms_set_strategy_named_str(StrategyIndex, VariableName, VariableValue)` |
| `pmms_strategies_allow_entries_all` | `pmms_strategies_allow_entries_all` |
| `pmms_strategies_count` | `pmms_strategies_count` |
| `pmms_strategies_deny_entries_all` | `pmms_strategies_deny_entries_all` |
| `pmms_strategies_get_by_symbol_name` | `pmms_strategies_get_by_symbol_name(SymbolName)` |
| `pmms_strategies_in_long_count` | `pmms_strategies_in_long_count(indexesArray)` |
| `pmms_strategies_in_positions_count` | `pmms_strategies_in_positions_count(indexesArray)` |
| `pmms_strategies_in_short_count` | `pmms_strategies_in_short_count(indexesArray)` |
| `pmms_strategies_pause_all` | `pmms_strategies_pause_all` |
| `pmms_strategies_resume_all` | `pmms_strategies_resume_all` |
| `pmms_strategies_set_status_for_all` | `pmms_strategies_set_status_for_all(Status)` |
| `pmms_strategy_allow_entries` | `pmms_strategy_allow_entries(StrategyIndex)` |
| `pmms_strategy_allow_exit_from_long` | `` |
| `pmms_strategy_allow_exit_from_short` | `` |
| `pmms_strategy_allow_exits` | `pmms_strategy_allow_exits(StrategyIndex)` |
| `pmms_strategy_allow_long_entries` | `` |
| `pmms_strategy_allow_short_entries` | `` |
| `pmms_strategy_avgentryprice` | `pmms_strategy_avgentryprice(StrategyIndex)` |
| `pmms_strategy_close_position` | `pmms_strategy_close_position(Index)` |
| `pmms_strategy_close_position_partial` | `pmms_strategy_close_position_partial(Index, isNextBar, contracts)` |
| `pmms_strategy_currentcontracts` | `pmms_strategy_currentcontracts(StrategyIndex)` |
| `pmms_strategy_deny_entries` | `pmms_strategy_deny_entries(StrategyIndex)` |
| `pmms_strategy_deny_exit_from_long` | `` |
| `pmms_strategy_deny_exit_from_short` | `` |
| `pmms_strategy_deny_exits` | `pmms_strategy_deny_exits(StrategyIndex)` |
| `pmms_strategy_deny_long_entries` | `` |
| `pmms_strategy_deny_short_entries` | `` |
| `pmms_strategy_entryprice` | `pmms_strategy_entryprice(StrategyIndex)` |
| `pmms_strategy_get_entry_contracts` | `pmms_strategy_get_entry_contracts(StrategyIndex)` |
| `pmms_strategy_is_paused` | `pmms_strategy_is_paused(StrategyIndex)` |
| `pmms_strategy_marketposition` | `pmms_strategy_marketposition(StrategyIndex)` |
| `pmms_strategy_maxiddrawdown` | `pmms_strategy_maxiddrawdown(StrategyIndex)` |
| `pmms_strategy_netprofit` | `pmms_strategy_netprofit(StrategyIndex)` |
| `pmms_strategy_openprofit` | `pmms_strategy_openprofit(StrategyIndex)` |
| `pmms_strategy_pause` | `pmms_strategy_pause(StrategyIndex)` |
| `pmms_strategy_resume` | `pmms_strategy_resume(StrategyIndex)` |
| `pmms_strategy_riskcapital` | `pmms_strategy_riskcapital(StrategyIndex)` |
| `pmms_strategy_set_entry_contracts` | `pmms_strategy_set_entry_contracts(StrategyIndex, Contracts)` |
| `pmms_strategy_set_status` | `pmms_strategy_set_status(StrategyIndex, Status)` |
| `pmms_strategy_symbol` | `pmms_strategy_symbol(StrategyIndex)` |

## Portfolio_Strategy_Performance

| Keyword | Signature |
|---|---|
| `Portfolio_GrossLoss` | `Portfolio_GrossLoss` |
| `Portfolio_GrossProfit` | `Portfolio_GrossProfit` |
| `Portfolio_InvestedCapital` | `Portfolio_InvestedCapital` |
| `Portfolio_MaxIDDrawdown` | `Portfolio_MaxIDDrawdown` |
| `Portfolio_NetProfit` | `Portfolio_NetProfit` |
| `Portfolio_NumLossTrades` | `Portfolio_NumLossTrades` |
| `Portfolio_NumWinTrades` | `Portfolio_NumWinTrades` |
| `Portfolio_PercentProfit` | `Portfolio_PercentProfit` |
| `Portfolio_StrategyDrawdown` | `Portfolio_StrategyDrawdown` |
| `Portfolio_TotalTrades` | `Portfolio_TotalTrades` |

## Portfolio_Strategy_Position

| Keyword | Signature |
|---|---|
| `Portfolio_CalcMaxPotentialLossForEntry` | `Portfolio_CalcMaxPotentialLossForEntry (Side [,Contracts [,Price]]);` |
| `Portfolio_CurrentEntries` | `Portfolio_CurrentEntries` |
| `Portfolio_MaxOpenPositionPotentialLoss` | `SetStopPosition;` |
| `Portfolio_OpenPositionProfit` | `Portfolio_OpenPositionProfit` |
| `Portfolio_SetMaxPotentialLossPerContract` | `Portfolio_SetMaxPotentialLossPerContract(NewValue);` |

## Portfolio_Strategy_Properties

| Keyword | Signature |
|---|---|
| `Portfolio_GetMarginPerContract` | `Portfolio_GetMarginPerContract` |
| `Portfolio_GetMaxPotentialLossPerContract` | `Portfolio_GetMaxPotentialLossPerContract` |
| `Portfolio_InterestRate` | `Portfolio_InterestRate` |
| `Portfolio_MaxRiskEquityPerPosPercent` | `Portfolio_MaxRiskEquityPerPosPercent` |
| `Portfolio_MinAcceptableRate` | `Portfolio_MinAcceptableRate` |
| `Portfolio_TotalMaxRiskEquityPercent` | `Portfolio_TotalMaxRiskEquityPercent` |
| `PortfolioEntriesPriority` | `PortfolioEntriesPriority=Priority` |

## Quote_Fields

| Keyword | Signature |
|---|---|
| `AskSize` | `AskSize` |
| `BidSize` | `BidSize` |
| `CurrentOpenInt` | `CurrentOpenInt` |
| `DailyClose` | `DailyClose` |
| `DailyHigh` | `DailyHigh` |
| `DailyLow` | `DailyLow` |
| `DailyOpen` | `DailyOpen` |
| `DailyVolume` | `DailyVolume` |
| `Description` | `Description` |
| `ExchListed` | `ExchListed` |
| `InsideAsk` | `InsideAsk` |
| `InsideBid` | `InsideBid` |
| `Last` | `Last` |
| `PrevClose` | `PrevClose` |
| `q_Ask` | `` |
| `q_asksize` | `` |
| `q_Bid` | `` |
| `q_bidsize` | `` |
| `q_BigPointValue` | `` |
| `q_Date` | `` |
| `q_ExchangeListed` | `` |
| `q_Last` | `` |
| `q_OpenInterest` | `` |
| `q_PreviousClose` | `` |
| `q_Time` | `` |
| `q_Time_Dt` | `q_Time_Dt` |
| `q_Time_s` | `` |
| `q_TotalVolume` | `` |
| `q_tradevolume` | `` |
| `RTSymbol` | `` |
| `RTSymbolName` | `RTSymbolName` |
| `Symbol` | `` |
| `SymbolName` | `SymbolName` |
| `SymbolRoot` | `SymbolRoot` |
| `TradeDate` | `TradeDate` |
| `TradeTime` | `TradeTime` |
| `TradeVolume` | `TradeVolume` |

## Rectangle_Drawing

| Keyword | Signature |
|---|---|
| `RectangleAnchorToBars` | `RectangleAnchorToBars(ID,LogicalExpression)` |
| `RectangleDelete` | `RectangleDelete(TL_ID)` |
| `RectangleGetActive` | `RectangleGetActive` |
| `RectangleGetAnchorToBars` | `RectangleGetAnchorToBars(ID)` |
| `RectangleGetBegin_BN` | `RectangleGetBegin_BN(ID)` |
| `RectangleGetBegin_DT` | `RectangleGetBegin_DT(ID)` |
| `RectangleGetBeginDate` | `RectangleGetBeginDate(ID)` |
| `RectangleGetBeginPrice` | `RectangleGetBeginPrice(ID)` |
| `RectangleGetBeginTime` | `RectangleGetBeginTime(ID)` |
| `RectangleGetBeginTime_s` | `RectangleGetBeginTime_s(ID)` |
| `RectangleGetColor` | `RectangleGetColor(ID)` |
| `RectangleGetEnd_BN` | `RectangleGetEnd_BN(ID)` |
| `RectangleGetEnd_DT` | `RectangleGetEnd_DT(ID)` |
| `RectangleGetEndDate` | `RectangleGetEndDate(ID)` |
| `RectangleGetEndPrice` | `RectangleGetEndPrice(ID)` |
| `RectangleGetEndTime` | `RectangleGetEndTime(ID)` |
| `RectangleGetEndTime_s` | `RectangleGetEndTime_s(ID)` |
| `RectangleGetFillColor` | `RectangleGetFillColor(ID)` |
| `RectangleGetFirst` | `RectangleGetFirst (Origin) Parameters` |
| `RectangleGetLock` | `RectangleGetLock(ID)` |
| `RectangleGetNext` | `RectangleGetNext (ID,Origin) Parameters` |
| `RectangleGetSize` | `RectangleGetSize(ID)` |
| `RectangleGetStyle` | `RectangleGetStyle(ID)` |
| `RectangleLock` | `RectangleLock(ID,LogicalExpression)` |
| `RectangleNew` | `RectangleNew (sDate, sTime, sPriceValue, eDate, eTime, ePriceValue) Parameters` |
| `RectangleNew_BN` | `RectangleNew_BN (b_BarNumber, b_Price, e_BarNumber, e_Price); Parameters` |
| `RectangleNew_DT` | `RectangleNew_DT (b_DateTime, b_Price, e_DateTime, e_Price); Parameters` |
| `RectangleNew_s` | `RectangleNew_s (sDate, sTime_s, sPriceValue, eDate, eTime_s, ePriceValue) Parameters` |
| `RectangleNewSelf` | `RectangleNewSelf (sDate, sTime, sPriceValue, eDate, eTime, ePriceValue) Parameters` |
| `RectangleNewSelf_BN` | `` |
| `RectangleNewSelf_DT` | `` |
| `RectangleNewSelf_s` | `` |
| `RectangleSetBegin` | `RectangleSetBegin (ID, sDate, sTime, sPriceValue) Parameters` |
| `RectangleSetBegin_BN` | `RectangleSetBegin_BN (ID, BarNumber, Price); Parameters` |
| `RectangleSetBegin_DT` | `RectangleSetBegin_DT (ID, b_DateTime, b_Price); Parameters` |
| `RectangleSetBegin_s` | `RectangleSetBegin_s (ID, sDate, sTime_s, sPriceValue) Parameters` |
| `RectangleSetColor` | `RectangleSetColor(ID,Color) Parameters` |
| `RectangleSetEnd` | `RectangleSetEnd (ID, eDate, eTime, ePriceValue) Parameters` |
| `RectangleSetEnd_BN` | `RectangleSetEnd_BN (ID, BarNumber, Price); Parameters` |
| `RectangleSetEnd_DT` | `RectangleSetEnd_DT (ID, e_DateTime, e_Price); Parameters` |
| `RectangleSetEnd_s` | `RectangleSetEnd_s (ID, eDate, eTime_s, ePriceValue) Parameters` |
| `RectangleSetFillColor` | `RectangleSetFillColor(ID,Color) Parameters` |
| `RectangleSetSize` | `RectangleSetSize(ID,LineWidth)` |
| `RectangleSetStyle` | `RectangleSetStyle(ID,Style) Parameters` |

## Sessions

| Keyword | Signature |
|---|---|
| `AutoSession` | `` |
| `RegularSession` | `` |
| `Sess1EndTime` | `` |
| `Sess1FirstBarTime` | `` |
| `Sess1StartTime` | `` |
| `Sess2EndTime` | `` |
| `Sess2FirstBarTime` | `` |
| `Sess2StartTime` | `` |
| `SessionCount` | `SessionCount(SessionType);` |
| `SessionCountMS` | `` |
| `SessionEndDay` | `See official docs for signature details.` |
| `SessionEndDayMS` | `SessionEndDayMS(SessionNum)` |
| `SessionEndTime` | `SessionEndTime(SessionType,SessionNum)` |
| `SessionEndTimeMS` | `SessionEndTimeMS(SessionNum)` |
| `SessionStartDay` | `SessionStartDay(SessionType,SessionNum)` |
| `SessionStartDayMS` | `SessionStartDayMS(SessionNum)` |
| `SessionStartTime` | `SessionStartTime(SessionType,SessionNum)` |
| `SessionStartTimeMS` | `SessionStartTimeMS(SessionNum)` |

## Skip_Words

| Keyword | Signature |
|---|---|
| `A` | `` |
| `An` | `` |
| `At` | `` |
| `Based` | `` |
| `By` | `` |
| `Does` | `` |
| `From` | `See official docs for signature details.` |
| `Is` | `` |
| `Of` | `` |
| `On` | `` |
| `Place` | `` |
| `Than` | `` |
| `The` | `` |
| `Was` | `` |

## Strategy_Events

| Keyword | Signature |
|---|---|
| `FilledOrderAction` | `FilledOrderAction` |
| `FilledOrderContracts` | `FilledOrderContracts` |
| `FilledOrderPrice` | `FilledOrderPrice` |
| `RejectedOrderAction` | `RejectedOrderAction` |
| `RejectedOrderCategory` | `RejectedOrderCategory` |
| `RejectedOrderContracts` | `RejectedOrderContracts` |
| `RejectedOrderLimitPrice` | `RejectedOrderLimitPrice` |
| `RejectedOrderStopPrice` | `RejectedOrderStopPrice` |

## Strategy_Orders

| Keyword | Signature |
|---|---|
| `All` | `All Contracts` |
| `Buy` | `Buy[("EntryLabel")][TradeSize]EntryType;` |
| `BuyToCover` | `BuyToCover[("ExitLabel")][From Entry("EntryLabel")][TradeSize[Total]]Exit` |
| `Contract` | `` |
| `Contracts` | `TradeSize Contracts` |
| `Cover` | `See official docs for signature details.` |
| `Entry` | `From Entry("EntryLabel")` |
| `Higher` | `At Price Or Higher` |
| `Limit` | `At Price Limit` |
| `Lower` | `At Price Or Lower` |
| `Market` | `At Market` |
| `Sell` | `Sell[("ExitLabel")][From Entry("EntryLabel")][TradeSize[Total]] Exit;` |
| `SellShort` | `SellShort[("EntryLabel")][TradeSize]Entry` |
| `SetBreakEven` | `SetBreakEven(Profit)` |
| `SetBreakEven_pt` | `SetBreakEven_pt(Profit)` |
| `SetDollarTrailing` | `SetDollarTrailing(Amount)` |
| `SetExitOnClose` | `SetExitOnClose` |
| `SetPercentTrailing` | `SetPercentTrailing(Profit,Percentage)` |
| `SetPercentTrailing_pt` | `SetPercentTrailing_pt(Profit,Percentage)` |
| `SetProfitTarget` | `SetProfitTarget(Amount)` |
| `SetProfitTarget_pt` | `SetProfitTarget_pt(Amount)` |
| `SetStopContract` | `SetStopContract` |
| `SetStopLoss` | `SetStopLoss(Amount)` |
| `SetStopLoss_pt` | `SetStopLoss_pt(Amount)` |
| `SetStopPosition` | `SetStopPosition` |
| `SetStopShare` | `` |
| `SetTrailingStop_pt` | `SetTrailingStop_pt(Amount)` |
| `Share` | `` |
| `Shares` | `TradeSize Shares` |
| `Short` | `Sell Short[("EntryLabel")][TradeSize]Entry;` |
| `Stop` | `At Price Stop` |
| `Total` | `TradeSize Shares Total` |

## Strategy_Performance

| Keyword | Signature |
|---|---|
| `AvgBarsEvenTrade` | `AvgBarsEvenTrade` |
| `AvgBarsLosTrade` | `AvgBarsLosTrade` |
| `AvgBarsWinTrade` | `AvgBarsWinTrade` |
| `AvgEntryPrice` | `AvgEntryPrice` |
| `AvgEntryPrice_at_Broker` | `AvgEntryPrice_at_Broker` |
| `AvgEntryPrice_at_Broker_for_The_Strategy` | `AvgEntryPrice_at_Broker_for_The_Strategy` |
| `GrossLoss` | `GrossLoss` |
| `GrossProfit` | `GrossProfit` |
| `i_AvgEntryPrice` | `` |
| `i_AvgEntryPrice_at_Broker` | `` |
| `i_AvgEntryPrice_at_Broker_for_The_Strategy` | `` |
| `i_ClosedEquity` | `i_ClosedEquity` |
| `i_CurrentContracts` | `` |
| `i_CurrentShares` | `` |
| `i_MarketPosition` | `i_MarketPosition` |
| `i_OpenEquity` | `i_OpenEquity` |
| `LargestLosTrade` | `LargestLosTrade` |
| `LargestWinTrade` | `LargestWinTrade` |
| `MaxConsecLosers` | `MaxConsecLosers` |
| `MaxConsecWinners` | `MaxConsecWinners` |
| `MaxContractsHeld` | `MaxContractsHeld` |
| `MaxIDDrawDown` | `MaxIDDrawDown` |
| `MaxSharesHeld` | `` |
| `NetProfit` | `NetProfit` |
| `NumEvenTrades` | `NumEvenTrades` |
| `NumLosTrades` | `NumLosTrades` |
| `NumWinTrades` | `NumWinTrades` |
| `PercentProfit` | `PercentProfit` |
| `SetCustomFitnessNamedValue` | `SetCustomFitnessNamedValue(CriterionName, Criterion)` |
| `SetCustomFitnessValue` | `SetCustomFitnessValue(Criterion)` |
| `TotalBarsEvenTrades` | `TotalBarsEvenTrades` |
| `TotalBarsLosTrades` | `TotalBarsLosTrades` |
| `TotalBarsWinTrades` | `TotalBarsWinTrades` |
| `TotalTrades` | `TotalTrades` |

## Strategy_Position

| Keyword | Signature |
|---|---|
| `BarsSinceEntry` | `BarsSinceEntry(PosBack)` |
| `BarsSinceEntry_Checked` | `BarsSinceEntry_Checked(PosBack)` |
| `BarsSinceExit` | `BarsSinceExit(PosBack)` |
| `BarsSinceExit_Checked` | `BarsSinceExit_Checked(PosBack)` |
| `ContractProfit` | `ContractProfit` |
| `CurrentContracts` | `CurrentContracts` |
| `CurrentEntries` | `CurrentEntries` |
| `CurrentShares` | `` |
| `EntryDate` | `EntryDate(PosBack)` |
| `EntryDate_Checked` | `EntryDate_Checked(PosBack)` |
| `EntryDateTime` | `EntryDateTime(PosBack)` |
| `EntryDateTime_Checked` | `EntryDateTime_Checked(PosBack)` |
| `EntryName` | `EntryName(PosBack)` |
| `EntryPrice` | `EntryPrice(PosBack)` |
| `EntryPrice_Checked` | `EntryPrice_Checked(PosBack)` |
| `EntryTime` | `EntryTime(PosBack)` |
| `EntryTime_Checked` | `EntryTime_Checked(PosBack)` |
| `ExitDate` | `ExitDate(PosBack)` |
| `ExitDate_Checked` | `ExitDate_Checked(PosBack)` |
| `ExitDateTime` | `ExitDateTime(PosBack)` |
| `ExitDateTime_Checked` | `ExitDateTime_Checked(PosBack)` |
| `ExitName` | `ExitName(PosBack)` |
| `ExitPrice` | `ExitPrice(PosBack)` |
| `ExitPrice_Checked` | `ExitPrice_Checked(PosBack)` |
| `ExitTime` | `ExitTime(PosBack)` |
| `ExitTime_Checked` | `ExitTime_Checked(PosBack)` |
| `i_MarketPosition_at_Broker` | `i_MarketPosition_at_Broker` |
| `i_MarketPosition_at_Broker_for_The_Strategy` | `i_MarketPosition_at_Broker_for_The_Strategy` |
| `MarketPosition` | `MarketPosition(PosBack)` |
| `MarketPosition_at_Broker` | `MarketPosition_at_Broker` |
| `MarketPosition_at_Broker_for_The_Strategy` | `MarketPosition_at_Broker_for_The_Strategy` |
| `MarketPosition_Checked` | `MarketPosition_Checked(PosBack)` |
| `MaxContractProfit` | `MaxContractProfit` |
| `MaxContractProfit_Checked` | `MaxContractProfit_Checked` |
| `MaxContracts` | `MaxContracts(PosBack)` |
| `MaxContracts_Checked` | `MaxContracts_Checked(PosBack)` |
| `MaxEntries` | `MaxEntries(PosBack)` |
| `MaxEntries_Checked` | `MaxEntries_Checked(PosBack)` |
| `MaxPositionLoss` | `MaxPositionLoss(PosBack)` |
| `MaxPositionLoss_Checked` | `MaxPositionLoss_Checked(PosBack)` |
| `MaxPositionProfit` | `MaxPositionProfit(PosBack)` |
| `MaxPositionProfit_Checked` | `MaxPositionProfit_Checked(PosBack)` |
| `MaxPositionsAgo` | `MaxPositionsAgo` |
| `MaxShares` | `` |
| `MaxShares_Checked` | `` |
| `OpenPositionProfit` | `OpenPositionProfit` |
| `PositionProfit` | `PositionProfit(PosBack)` |
| `PositionProfit_Checked` | `PositionProfit_Checked(PosBack)` |

## Strategy_Position_Synchronization

| Keyword | Signature |
|---|---|
| `ChangeMarketPosition` | `ChangeMarketPosition (Delta, Price, Name)` |
| `PlaceMarketOrder` | `PlaceMarketOrder(IsBuy, IsEntry, Contracts)` |

## Strategy_Position_Trades

| Keyword | Signature |
|---|---|
| `OpenEntriesCount` | `` |
| `OpenEntryComission` | `OpenEntryComission(EntryIndex)` |
| `OpenEntryContracts` | `OpenEntryContracts(EntryIndex)` |
| `OpenEntryDate` | `OpenEntryDate(EntryIndex)` |
| `OpenEntryMaxProfit` | `OpenEntryMaxProfit(EntryIndex)` |
| `OpenEntryMaxProfitPerContract` | `OpenEntryMaxProfitPerContract(EntryIndex)` |
| `OpenEntryMinProfit` | `OpenEntryMinProfit(EntryIndex)` |
| `OpenEntryMinProfitPerContract` | `OpenEntryMinProfitPerContract(EntryIndex)` |
| `OpenEntryPrice` | `OpenEntryPrice(EntryIndex)` |
| `OpenEntryProfit` | `OpenEntryProfit(EntryIndex)` |
| `OpenEntryProfitPerContract` | `OpenEntryProfitPerContract(EntryIndex)` |
| `OpenEntryTime` | `OpenEntryTime(EntryIndex)` |
| `PosTradeCommission` | `PosTradeCommission(PosAgo,TradeNumber)` |
| `PosTradeCount` | `PosTradeCount(PosBack)` |
| `PosTradeEntryBar` | `PosTradeEntryBar(PosAgo,TradeNumber)` |
| `PosTradeEntryCategory` | `PosTradeEntryCategory(PosAgo,TradeNumber)` |
| `PosTradeEntryDateTime` | `PosTradeEntryDateTime(PosAgo,TradeNumber)` |
| `PosTradeEntryName` | `PosTradeEntryName(PosAgo,TradeNumber)` |
| `PosTradeEntryPrice` | `PosTradeEntryPrice(PosAgo,TradeNumber)` |
| `PosTradeExitBar` | `PosTradeExitBar(PosAgo,TradeNumber)` |
| `PosTradeExitCategory` | `PosTradeExitCategory(PosAgo,TradeNumber)` |
| `PosTradeExitDateTime` | `PosTradeExitDateTime(PosAgo,TradeNumber)` |
| `PosTradeExitName` | `PosTradeExitName(PosAgo,TradeNumber)` |
| `PosTradeExitPrice` | `PosTradeExitPrice(PosAgo,TradeNumber)` |
| `PosTradeIsLong` | `PosTradeIsLong(PosAgo,TradeNumber)` |
| `PosTradeIsOpen` | `PosTradeIsOpen(PosAgo,TradeNumber)` |
| `PosTradeProfit` | `PosTradeProfit(PosAgo,TradeNumber)` |
| `PosTradeSize` | `PosTradeSize(PosAgo,TradeNumber)` |

## Strategy_Properties

| Keyword | Signature |
|---|---|
| `Commission` | `Commission` |
| `GetStrategyName` | `` |
| `InterestRate` | `InterestRate` |
| `Margin` | `Margin` |
| `Slippage` | `Slippage` |

## Text_Drawing

| Keyword | Signature |
|---|---|
| `MC_Text_GetActive` | `MC_Text_GetActive` |
| `Text_Anchor_to_Bars` | `Text_Anchor_to_Bars(Text_ID,LogicalExpression)` |
| `Text_Delete` | `Text_Delete(ObjectID)` |
| `Text_Get_Anchor_to_Bars` | `Text_Get_Anchor_to_Bars(Text_ID)` |
| `Text_GetActive` | `Text_GetActive` |
| `Text_GetAttribute` | `Text_GetAttribute(ObjectID,Attribute) Parameters` |
| `Text_GetBarNumber` | `Text_GetBarNumber(ref);` |
| `Text_GetBGColor` | `Text_GetBGColor(ObjectID)` |
| `Text_GetBorder` | `Text_GetBorder(ObjectID)` |
| `Text_GetColor` | `Text_GetColor(ObjectID)` |
| `Text_GetDate` | `Text_GetDate(ObjectID)` |
| `Text_GetFirst` | `Text_GetFirst (Origin) Parameters` |
| `Text_GetFontName` | `Text_GetFontName(ObjectID)` |
| `Text_GetHStyle` | `Text_GetHStyle(ObjectID)` |
| `Text_GetLock` | `Text_GetLock(Text_ID)` |
| `Text_GetNext` | `Text_GetNext(ObjectID,Origin) Parameters` |
| `Text_GetSize` | `Text_GetSize(ObjectID)` |
| `Text_GetString` | `Text_GetString(ObjectID)` |
| `Text_GetTime` | `Text_GetTime(ObjectID)` |
| `Text_GetTime_DT` | `Text_GetTime_DT(ObjectID)` |
| `Text_GetTime_s` | `Text_GetTime_s(ObjectID)` |
| `Text_GetValue` | `Text_GetValue(ObjectID)` |
| `Text_GetVStyle` | `Text_GetVStyle(ObjectID)` |
| `Text_Lock` | `Text_Lock(Text_ID,LogicalExpression)` |
| `Text_New` | `Text_New (BarDate, BarTime, PriceValue,"Text") Parameters` |
| `Text_New_BN` | `Text_New_BN (BarNumber, PriceValue,"Text") Parameters` |
| `Text_New_Dt` | `Text_New_Dt (Bar_DateTime, PriceValue,"Text") Parameters` |
| `Text_New_s` | `Text_New_s (BarDate, BarTime_s, PriceValue,"Text") Parameters` |
| `Text_New_self` | `Text_New_self (BarDate, BarTime, PriceValue,"Text") Parameters` |
| `Text_New_Self_BN` | `` |
| `Text_New_Self_DT` | `Text_New_Self_DT (Bar_DateTime, PriceValue,"Text") Parameters` |
| `Text_New_self_s` | `Text_New_self_s (BarDate, BarTime_s, PriceValue,"Text") Parameters` |
| `Text_SetAttribute` | `Text_SetAttribute(ObjectID,Attribute,LogicalExpression) Parameters` |
| `Text_SetBarNumber` | `Text_SetBarNumber(ref,Barnumber)` |
| `Text_SetBGColor` | `Text_SetBGColor(ObjectID,BGColor) Parameters` |
| `Text_SetBorder` | `Text_SetBorder(ObjectID,LogicalExpression)` |
| `Text_SetColor` | `Text_SetColor(ObjectID,TextColor) Parameters` |
| `Text_SetFontName` | `Text_SetFontName(ObjectID,"FontName")` |
| `Text_SetLocation` | `Text_SetLocation (ObjectID, BarDate, BarTime, PriceValue) Parameters` |
| `Text_SetLocation_BN` | `Text_SetLocation_BN (ObjectID, BarNumber, PriceValue) Parameters` |
| `Text_SetLocation_DT` | `Text_SetLocation_DT (ObjectID, Bar_DateTime, PriceValue) Parameters` |
| `Text_SetLocation_s` | `Text_SetLocation_s (ObjectID, BarDate, BarTime_s, PriceValue) Parameters` |
| `Text_SetSize` | `Text_SetSize(ObjectID,FontSize)` |
| `Text_SetString` | `Text_SetString(ObjectID,"Text")` |
| `Text_SetStyle` | `Text_SetStyle (ObjectID, HorizPl, VertPl) Parameters` |
| `Text_SetTransparent` | `Text_SetTransparent (ref, state) Parameters` |

## Text_Manipulation

| Keyword | Signature |
|---|---|
| `DoubleQuote` | `` |
| `InStr` | `InStr(String1,String2)` |
| `LeftStr` | `LeftStr(String,sSize)` |
| `LowerStr` | `LowerStr("String")` |
| `MidStr` | `MidStr("String",Pos,Num)` |
| `NewLine` | `` |
| `NumToStr` | `NumToStr(Expression,Dec)` |
| `RightStr` | `RightStr(String,sSize)` |
| `Spaces` | `Spaces(Num)` |
| `StrLen` | `StrLen("String")` |
| `StrToNum` | `StrToNum("String")` |
| `Text` | `Text(Param1, Param2, ..., ParamN);` |
| `UpperStr` | `UpperStr("String")` |

## Trendline_Drawing

| Keyword | Signature |
|---|---|
| `MC_TL_GetActive` | `MC_TL_GetActive` |
| `MC_TL_New` | `` |
| `MC_TL_New_BN` | `` |
| `MC_TL_New_DT` | `` |
| `MC_TL_New_Self` | `` |
| `MC_TL_New_Self_BN` | `` |
| `MC_TL_New_Self_DT` | `` |
| `TL_Anchor_to_Bars` | `TL_Anchor_to_Bars(TL_ID,LogicalExpression)` |
| `TL_Delete` | `TL_Delete(TL_ID)` |
| `TL_Get_Anchor_to_Bars` | `TL_Get_Anchor_to_Bars(TL_ID)` |
| `TL_GetActive` | `TL_GetActive` |
| `TL_GetAlert` | `TL_GetAlert(TL_ID)` |
| `TL_GetBegin_BN` | `TL_GetBegin_BN(TL_ID)` |
| `TL_GetBegin_Dt` | `TL_GetBegin_Dt(TL_ID)` |
| `TL_GetBeginDate` | `TL_GetBeginDate(TL_ID)` |
| `TL_GetBeginTime` | `TL_GetBeginTime(TL_ID)` |
| `TL_GetBeginTime_s` | `TL_GetBeginTime_s(TL_ID)` |
| `TL_GetBeginVal` | `TL_GetBeginVal(TL_ID)` |
| `TL_GetColor` | `TL_GetColor(TL_ID)` |
| `TL_GetEnd_BN` | `TL_GetEnd_BN(TL_ID)` |
| `TL_GetEnd_Dt` | `TL_GetEnd_Dt(TL_ID)` |
| `TL_GetEndDate` | `TL_GetEndDate(TL_ID)` |
| `TL_GetEndTime` | `TL_GetEndTime(TL_ID)` |
| `TL_GetEndTime_s` | `TL_GetEndTime_s(TL_ID)` |
| `TL_GetEndVal` | `TL_GetEndVal(TL_ID)` |
| `TL_GetExtLeft` | `TL_GetExtLeft(TL_ID)` |
| `TL_GetExtRight` | `TL_GetExtRight(TL_ID)` |
| `TL_GetFirst` | `TL_GetFirst (Origin) Parameters` |
| `TL_GetLock` | `TL_GetLock(TL_ID)` |
| `TL_GetNext` | `TL_GetNext (TL_ID,Origin) Parameters` |
| `TL_GetSize` | `TL_GetSize(TL_ID)` |
| `TL_GetStyle` | `TL_GetStyle(TL_ID)` |
| `TL_GetValue` | `TL_GetValue (TL_ID, Date, Time) Parameters` |
| `TL_GetValue_BN` | `TL_GetValue_BN(TL_ID, Barnumber) Parameters` |
| `TL_GetValue_Dt` | `TL_GetValue_Dt(TL_ID, DT) Parameters` |
| `TL_GetValue_s` | `TL_GetValue_s (TL_ID, Date, Time_s) Parameters` |
| `TL_Lock` | `TL_Lock(TL_ID,LogicalExpression)` |
| `TL_New` | `TL_New (sDate, sTime, sPriceValue, eDate, eTime, ePriceValue) Parameters` |
| `TL_New_BN` | `TL_New_BN (b_BarNumber, b_Price, e_BarNumber, e_Price); Parameters` |
| `TL_New_Dt` | `TL_New_Dt (b_DateTime, b_Price, e_DateTime, e_Price); Parameters` |
| `TL_New_s` | `TL_New_s (sDate, sTime_s, sPriceValue, eDate, eTime_s, ePriceValue) Parameters` |
| `TL_New_self` | `TL_New_self (sDate, sTime, sPriceValue, eDate, eTime, ePriceValue) Parameters` |
| `TL_New_Self_BN` | `` |
| `TL_New_Self_Dt` | `TL_New_Self_Dt (b_DateTime, b_Price, e_DateTime, e_Price); Parameters` |
| `TL_New_Self_s` | `TL_New_s (sDate, sTime_s, sPriceValue, eDate, eTime_s, ePriceValue) Parameters` |
| `TL_SetAlert` | `TL_SetAlert(TL_ID,AlertStatus) Parameters` |
| `TL_SetBegin` | `TL_SetBegin (TL_ID, sDate, sTime, sPriceValue) Parameters` |
| `TL_SetBegin_BN` | `TL_SetBegin_BN (TL_ID, BarNumber, Price); Parameters` |
| `TL_SetBegin_DT` | `TL_SetBegin_DT (TL_ID, b_DateTime, b_Price); Parameters` |
| `TL_SetBegin_s` | `TL_SetBegin_s (TL_ID, sDate, sTime_s, sPriceValue) Parameters` |
| `TL_SetColor` | `TL_SetColor(TL_ID,TL_Color) Parameters` |
| `TL_SetEnd` | `TL_SetEnd (TL_ID, eDate, eTime, ePriceValue) Parameters` |
| `TL_SetEnd_BN` | `TL_SetEnd_BN (TL_ID, BarNumber, Price); Parameters` |
| `TL_SetEnd_Dt` | `TL_SetEnd_Dt (TL_ID, e_DateTime, e_Price); Parameters` |
| `TL_SetEnd_s` | `TL_SetEnd_s (TL_ID, eDate, eTime_s, ePriceValue) Parameters` |
| `TL_SetExtLeft` | `TL_SetExtLeft(TL_ID,LogicalExpression)` |
| `TL_SetExtRight` | `TL_SetExtRight(TL_ID,LogicalExpression)` |
| `TL_SetSize` | `TL_SetSize(TL_ID,LineWidth)` |
| `TL_SetStyle` | `TL_SetStyle(TL_ID,TL_Style) Parameters` |
| `Tool_Dashed` | `TL_SetStyle(TL_ID, Tool_Dashed)` |
| `Tool_Dashed2` | `TL_SetStyle(TL_ID, Tool_Dashed2)` |
| `Tool_Dashed3` | `TL_SetStyle(TL_ID, Tool_Dashed3)` |
| `Tool_Dotted` | `TL_SetStyle(TL_ID, Tool_Dotted)` |
| `Tool_Solid` | `TL_SetStyle(TL_ID, Tool_Solid)` |

