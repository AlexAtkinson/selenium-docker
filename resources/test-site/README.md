# Test Site

A simple vite demo.

These instructions are the same as in the main README.md.

## Build

```
docker build -t test-site:latest .
```

## Run

```
docker run --rm --name test-site -v ./src:/app/src/ -p 8080:5173 test-site:latest
```

Visit: http://localhost:8080/

## Original Readme

### Vue 3 + Vite

This template should help get you started developing with Vue 3 in Vite. The template uses Vue 3 `<script setup>` SFCs, check out the [script setup docs](https://v3.vuejs.org/api/sfc-script-setup.html#sfc-script-setup) to learn more.

Learn more about IDE Support for Vue in the [Vue Docs Scaling up Guide](https://vuejs.org/guide/scaling-up/tooling.html#ide-support).
