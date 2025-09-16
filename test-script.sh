#!/bin/bash
echo "Test script working"
echo "This is a test"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 1
fi
echo "Success"