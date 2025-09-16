import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Badge } from "@/components/ui/badge";
import { format } from "date-fns";
import { 
  Calendar as CalendarIcon, 
  Clock,
  ChevronLeft,
  ChevronRight
} from "lucide-react";
import { cn } from "@/lib/utils";

interface TimeFilterProps {
  value: {
    period: string;
    startDate: Date;
    endDate: Date;
  };
  onChange: (filter: { period: string; startDate: Date; endDate: Date }) => void;
  embedded?: boolean;
}

const TimeFilter = ({ value, onChange, embedded = false }: TimeFilterProps) => {
  // Safety check: return null if value is not properly defined
  if (!value || !value.startDate || !value.endDate) {
    return null;
  }

  const periods = [
    { id: "month", label: "Monthly", description: "Last 30 days" },
    { id: "custom", label: "Custom Range", description: "Select date range" },
  ];

  const handlePeriodChange = (period: string) => {
    const now = new Date();
    let startDate = new Date();
    
    switch (period) {
      case "month":
        startDate = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());
        break;
      case "custom":
        onChange({
          period: "custom",
          startDate: value?.startDate || new Date(),
          endDate: value?.endDate || new Date()
        });
        return;
      default:
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
    }

    onChange({
      period,
      startDate,
      endDate: now
    });
  };

  const navigatePeriod = (direction: "prev" | "next") => {
    if (!value) return;
    const { period, startDate, endDate } = value;
    const duration = endDate.getTime() - startDate.getTime();
    
    let newStart: Date;
    let newEnd: Date;
    
    if (direction === "prev") {
      newEnd = new Date(startDate.getTime() - 1);
      newStart = new Date(newEnd.getTime() - duration);
    } else {
      newStart = new Date(endDate.getTime() + 1);
      newEnd = new Date(newStart.getTime() + duration);
    }
    
    onChange({
      period,
      startDate: newStart,
      endDate: newEnd
    });
  };

  const Controls = (
        <div className={`flex flex-col lg:flex-row gap-4 ${embedded ? '' : 'items-start lg:items-center'}`}>
          {/* Period Selection */}
          <div className="flex-1">
            <Select value={value?.period} onValueChange={handlePeriodChange}>
              <SelectTrigger className="w-full lg:w-48">
                <SelectValue placeholder="Select period" />
              </SelectTrigger>
              <SelectContent>
                {periods.map((period) => (
                  <SelectItem key={period.id} value={period.id}>
                    <div className="flex flex-col">
                      <span className="font-medium">{period.label}</span>
                      <span className="text-xs text-muted-foreground">{period.description}</span>
                    </div>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Date Range Display & Navigation */}
          {value?.period !== "custom" && (
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => navigatePeriod("prev")}
              >
                <ChevronLeft className="h-4 w-4" />
              </Button>
              
              <Badge variant="outline" className="px-3 py-1">
                {value?.startDate && value?.endDate ? 
                  `${format(value.startDate, "MMM dd")} - ${format(value.endDate, "MMM dd, yyyy")}` : 
                  "Loading..."
                }
              </Badge>
              
              <Button
                variant="outline"
                size="sm"
                onClick={() => navigatePeriod("next")}
                disabled={!value?.endDate || value.endDate >= new Date()}
              >
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          )}

          {/* Custom Date Range */}
          {value?.period === "custom" && (
            <div className="flex items-center gap-2">
              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    variant="outline"
                    className={cn(
                      "justify-start text-left font-normal",
                      !value?.startDate && "text-muted-foreground"
                    )}
                  >
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {value?.startDate ? format(value.startDate, "PPP") : "Start date"}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar
                    mode="single"
                    selected={value?.startDate}
                    onSelect={(date) => date && onChange({ ...(value || {}), startDate: date })}
                    initialFocus
                    className="p-3 pointer-events-auto"
                  />
                </PopoverContent>
              </Popover>

              <span className="text-muted-foreground">to</span>

              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    variant="outline"
                    className={cn(
                      "justify-start text-left font-normal",
                      !value?.endDate && "text-muted-foreground"
                    )}
                  >
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {value?.endDate ? format(value.endDate, "PPP") : "End date"}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar
                    mode="single"
                    selected={value?.endDate}
                    onSelect={(date) => date && onChange({ ...(value || {}), endDate: date })}
                    initialFocus
                    className="p-3 pointer-events-auto"
                  />
                </PopoverContent>
              </Popover>
            </div>
          )}
        </div>
  );

  if (embedded) {
    return (
      <div className="mt-2">{Controls}</div>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Clock className="h-5 w-5" />
          Time Period Filter
        </CardTitle>
        <CardDescription>
          Adjust the time range to analyze data for specific periods
        </CardDescription>
      </CardHeader>
      <CardContent>
        {Controls}
      </CardContent>
    </Card>
  );
};

export default TimeFilter;