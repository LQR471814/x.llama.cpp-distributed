BIN_DIR := "./llama.cpp/build/bin"
BUILD_PARALLEL := 12

llama.cpp:
	git clone "https://github.com/ggml-org/llama.cpp.git" --depth 1

.bin: llama.cpp
	cd llama.cpp && \
		mkdir -p build && \
		cd build && \
		cmake .. $(EXTRA_CMAKE_FLAGS) -DGGML_RPC=ON && \
		cmake --build . --config Release -j $(BUILD_PARALLEL)
	touch .bin

remote: .bin
	$(BIN_DIR)/rpc-server -p 50052 -H 0.0.0.0

models:
	mkdir models

models/Qwen3-Coder-30B-A3B-Instruct-UD-Q8_K_XL.gguf: models
	curl -o models/Qwen3-Coder-30B-A3B-Instruct-UD-Q8_K_XL.gguf -L https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF/resolve/main/Qwen3-Coder-30B-A3B-Instruct-UD-Q8_K_XL.gguf?download=true

models/Qwen3-14B-Q6_K.gguf: models
	curl -o models/Qwen3-14B-Q6_K.gguf -L https://huggingface.co/Qwen/Qwen3-14B-GGUF/resolve/main/Qwen3-14B-Q6_K.gguf?download=true

models/Qwen3-0.6B-Q6_K.gguf: models
	curl -o models/Qwen3-0.6B-Q6_K.gguf -L https://huggingface.co/unsloth/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q6_K.gguf?download=true

models/Qwen3-4B-Thinking-2507-Q6_K.gguf: models
	curl -o models/Qwen3-4B-Thinking-2507-Q6_K.gguf -L https://huggingface.co/unsloth/Qwen3-4B-Thinking-2507-GGUF/resolve/main/Qwen3-4B-Thinking-2507-Q6_K.gguf?download=true

models/Qwen3-Embedding-0.6B-Q8_0.gguf: models
	curl -o models/Qwen3-Embedding-0.6B-Q8_0.gguf -L https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF/blob/main/Qwen3-Embedding-0.6B-Q8_0.gguf

main: .bin models
	$(BIN_DIR)/llama-cli \
			--models-dir models \
			--rpc 192.168.20.2:50052

main-server: .bin models
	$(BIN_DIR)/llama-server \
			--port 8080 \
			--host 0.0.0.0 \
			--models-dir models \
			--rpc 192.168.20.2:50052

local: .bin models models/Qwen3-0.6B-Q6_K.gguf
	# perf tuning:
	# -fa = flash attention (usually faster)
	# -t = # of CPU threads (should be <= physical cores, not hyper-thread because that causes memory-thrashing)
	# -ub should be < -b
	# -ctk = quantize context (q6 quantization of the model doesn't extend to the context, we can quantize context for negligible perf loss and save memory)
	$(BIN_DIR)/llama-server --port 8080 --models-dir models \
		-fa on -t 9 \
		-b 4096 \
		-ub 512 \
		-ctk q8_0 -ctv q8_0 \

