"use client";

import { useEffect, useState } from "react";
import {
    LineChart,
    Line,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer,
} from "recharts";
import { getSocket } from "../lib/socket";

interface DataPoint {
    time: string;
    transactions: number;
    frauds: number;
}

export default function RealTimeChart() {
    const [data, setData] = useState<DataPoint[]>([]);

    useEffect(() => {
        const socket = getSocket();
        const channel = socket.channel("fraud:alerts", {});

        channel
            .join()
            .receive("ok", () => console.log("Connected to Fraud Channel"))
            .receive("error", (resp: any) => console.log("Unable to join", resp));

        channel.on("new_batch", (payload: { frauds: any[] }) => {
            // Simulate throughput data for the chart based on alerts
            // In a real app, we would receive explicit throughput stats
            const now = new Date().toLocaleTimeString();
            const newPoint = {
                time: now,
                transactions: Math.floor(Math.random() * 100) + 50, // Mock throughput
                frauds: payload.frauds.length,
            };

            setData((prev) => [...prev.slice(-20), newPoint]); // Keep last 20 points
        });

        return () => {
            channel.leave();
        };
    }, []);

    return (
        <div className="h-[300px] w-full bg-slate-900 p-4 rounded-xl border border-slate-800">
            <h3 className="text-slate-400 mb-4 text-sm font-mono">LIVE THREAT MONITOR</h3>
            <ResponsiveContainer width="100%" height="100%">
                <LineChart data={data}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                    <XAxis dataKey="time" stroke="#94a3b8" fontSize={12} />
                    <YAxis stroke="#94a3b8" fontSize={12} />
                    <Tooltip
                        contentStyle={{ backgroundColor: "#1e293b", border: "none" }}
                        itemStyle={{ color: "#e2e8f0" }}
                    />
                    <Line
                        type="monotone"
                        dataKey="transactions"
                        stroke="#3b82f6"
                        strokeWidth={2}
                        dot={false}
                    />
                    <Line
                        type="monotone"
                        dataKey="frauds"
                        stroke="#ef4444"
                        strokeWidth={2}
                    />
                </LineChart>
            </ResponsiveContainer>
        </div>
    );
}
