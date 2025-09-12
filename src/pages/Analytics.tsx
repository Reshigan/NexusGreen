import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { ScrollArea } from "@/components/ui/scroll-area";
import { 
  Bot, 
  Send, 
  Download,
  TrendingUp,
  AlertTriangle,
  Lightbulb,
  MessageCircle
} from "lucide-react";
import DashboardLayout from "@/components/DashboardLayout";
import AnalyticsChart from "@/components/AnalyticsChart";
import TimeFilter from "@/components/TimeFilter";

interface ChatMessage {
  id: string;
  type: "user" | "ai";
  content: string;
  timestamp: Date;
  insights?: string[];
}

const Analytics = () => {
  const [message, setMessage] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [timeFilter, setTimeFilter] = useState({
    period: "month",
    startDate: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
    endDate: new Date()
  });
  const [chatHistory, setChatHistory] = useState<ChatMessage[]>([
    {
      id: "1",
      type: "ai",
      content: "Hello! I'm your AI analytics assistant. I can help you analyze your solar plant performance, identify trends, and provide insights. What would you like to know about your solar investments?",
      timestamp: new Date(),
      insights: ["Performance Analysis", "Cost Optimization", "Maintenance Predictions"]
    }
  ]);

  const handleSendMessage = async () => {
    if (!message.trim()) return;

    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      type: "user",
      content: message,
      timestamp: new Date()
    };

    setChatHistory(prev => [...prev, userMessage]);
    setMessage("");
    setIsLoading(true);

    // TODO: Replace with actual AI API integration
    setTimeout(() => {
      const aiResponse: ChatMessage = {
        id: (Date.now() + 1).toString(),
        type: "ai",
        content: generateMockResponse(message),
        timestamp: new Date(),
        insights: generateMockInsights(message)
      };
      
      setChatHistory(prev => [...prev, aiResponse]);
      setIsLoading(false);
    }, 2000);
  };

  const generateMockResponse = (userMessage: string): string => {
    const lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.includes("performance") || lowerMessage.includes("yield")) {
      return "Based on your portfolio analysis, your solar plants are performing at 94.2% efficiency. Plant Alpha in California is your top performer with 96.8% efficiency, while Plant Delta could benefit from maintenance optimization. The overall yield has increased by 12% this month.";
    } else if (lowerMessage.includes("savings") || lowerMessage.includes("financial")) {
      return "Your total savings have reached $48,560 this quarter, representing an 8% increase. The ROI analysis shows you're on track to recover your investment 6 months ahead of schedule. I recommend optimizing maintenance schedules to maximize these savings.";
    } else if (lowerMessage.includes("maintenance") || lowerMessage.includes("issues")) {
      return "Predictive analysis indicates that Plant Charlie may require inverter maintenance within the next 30 days based on temperature trends. Plant Bravo shows optimal performance patterns. I recommend scheduling preventive maintenance for 3 plants to avoid efficiency drops.";
    } else {
      return "I can help you with performance analysis, financial insights, maintenance predictions, and trend analysis. Please let me know what specific aspect of your solar portfolio you'd like to explore.";
    }
  };

  const generateMockInsights = (userMessage: string): string[] => {
    const lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.includes("performance")) {
      return ["Optimize Plant Delta efficiency", "Consider weather impact analysis", "Review inverter performance"];
    } else if (lowerMessage.includes("savings")) {
      return ["ROI ahead of schedule", "Maintenance cost optimization", "Energy price forecasting"];
    } else if (lowerMessage.includes("maintenance")) {
      return ["Preventive maintenance scheduling", "Temperature monitoring", "Component lifecycle analysis"];
    } else {
      return ["Performance trending", "Cost analysis", "Predictive insights"];
    }
  };

  const handleExportAnalytics = () => {
    // TODO: Implement analytics export functionality
    console.log("Exporting analytics data as CSV for period:", timeFilter);
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-3xl font-bold text-foreground">AI Analytics & Insights</h1>
            <p className="text-muted-foreground">Get intelligent insights about your solar portfolio</p>
          </div>
          <Button 
            variant="outline" 
            size="sm"
            onClick={handleExportAnalytics}
          >
            <Download className="h-4 w-4 mr-2" />
            Export Analytics
          </Button>
        </div>

        {/* Time Filter */}
        <TimeFilter 
          value={timeFilter}
          onChange={setTimeFilter}
        />

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Analytics Overview */}
          <div className="lg:col-span-2 space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="h-5 w-5" />
                  Performance Analytics
                </CardTitle>
                <CardDescription>
                  AI-powered insights into your solar portfolio performance
                </CardDescription>
              </CardHeader>
              <CardContent>
                <AnalyticsChart />
              </CardContent>
            </Card>

            {/* Key Insights Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Card>
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm font-medium flex items-center gap-2">
                    <Lightbulb className="h-4 w-4 text-warning" />
                    Optimization
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground">
                    Plant Delta efficiency can be improved by 3.2% with inverter optimization
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm font-medium flex items-center gap-2">
                    <AlertTriangle className="h-4 w-4 text-destructive" />
                    Maintenance Alert
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground">
                    Predictive maintenance needed for Plant Charlie in 30 days
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm font-medium flex items-center gap-2">
                    <TrendingUp className="h-4 w-4 text-success" />
                    Performance
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground">
                    Portfolio outperforming benchmark by 12% this quarter
                  </p>
                </CardContent>
              </Card>
            </div>
          </div>

          {/* AI Chat Interface */}
          <div className="lg:col-span-1">
            <Card className="h-[600px] flex flex-col">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Bot className="h-5 w-5 text-accent" />
                  AI Assistant
                </CardTitle>
                <CardDescription>
                  Ask questions about your solar portfolio
                </CardDescription>
              </CardHeader>
              
              <CardContent className="flex-1 flex flex-col p-0">
                <ScrollArea className="flex-1 px-4">
                  <div className="space-y-4 pb-4">
                    {chatHistory.map((msg) => (
                      <div
                        key={msg.id}
                        className={`flex ${msg.type === "user" ? "justify-end" : "justify-start"}`}
                      >
                        <div
                          className={`max-w-[85%] rounded-lg p-3 ${
                            msg.type === "user"
                              ? "bg-primary text-primary-foreground"
                              : "bg-muted"
                          }`}
                        >
                          <p className="text-sm">{msg.content}</p>
                          {msg.insights && (
                            <div className="mt-2 flex flex-wrap gap-1">
                              {msg.insights.map((insight, index) => (
                                <Badge key={index} variant="secondary" className="text-xs">
                                  {insight}
                                </Badge>
                              ))}
                            </div>
                          )}
                          <p className="text-xs opacity-70 mt-1">
                            {msg.timestamp.toLocaleTimeString()}
                          </p>
                        </div>
                      </div>
                    ))}
                    
                    {isLoading && (
                      <div className="flex justify-start">
                        <div className="bg-muted rounded-lg p-3 max-w-[85%]">
                          <div className="flex items-center gap-2">
                            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-accent"></div>
                            <span className="text-sm">Analyzing data...</span>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                </ScrollArea>
                
                <div className="p-4 border-t">
                  <div className="flex gap-2">
                    <Input
                      placeholder="Ask about performance, savings, maintenance..."
                      value={message}
                      onChange={(e) => setMessage(e.target.value)}
                      onKeyPress={(e) => e.key === "Enter" && handleSendMessage()}
                      disabled={isLoading}
                    />
                    <Button 
                      size="sm" 
                      onClick={handleSendMessage}
                      disabled={isLoading || !message.trim()}
                    >
                      <Send className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default Analytics;