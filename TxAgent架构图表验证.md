# TxAgent项目架构图表验证

## 图表1：系统架构图

```mermaid
graph TB
    %% 用户交互层
    User[👤 用户输入<br/>医疗问题] --> TxAgent[🤖 TxAgent核心引擎]
    
    %% TxAgent核心组件
    TxAgent --> LLM[🧠 vLLM推理引擎<br/>Llama-3.1-8B]
    TxAgent --> ToolRAG[🔍 ToolRAG系统<br/>工具检索与匹配]
    TxAgent --> ToolUniverse[🛠️ ToolUniverse<br/>211个生物医学工具]
    TxAgent --> ReasoningEngine[⚡ 多步推理引擎<br/>逐步分析与决策]
    
    %% ToolRAG子系统
    ToolRAG --> EmbeddingModel[📊 嵌入模型<br/>GTE-Qwen2-1.5B]
    ToolRAG --> ToolEmbedding[💾 工具描述嵌入<br/>向量化存储]
    
    %% ToolUniverse工具分类
    ToolUniverse --> FDATools[🏥 FDA工具集<br/>药物标签/适应症]
    ToolUniverse --> OpenTargets[🎯 OpenTargets工具<br/>靶点/疾病关联]
    ToolUniverse --> MonarchTools[👑 Monarch工具<br/>表型/疾病数据]
    ToolUniverse --> SpecialTools[⚙️ 特殊工具<br/>Finish/CallAgent]
    
    %% 推理引擎组件
    ReasoningEngine --> ConversationManager[💬 对话管理器<br/>上下文维护]
    ReasoningEngine --> FunctionCaller[📞 函数调用器<br/>工具执行管理]
    ReasoningEngine --> ReasoningChecker[✅ 推理检查器<br/>重复检测]
    
    %% 输出处理
    FunctionCaller --> ToolResults[📋 工具执行结果]
    ToolResults --> ResponseGenerator[📝 响应生成器]
    ResponseGenerator --> FinalAnswer[✨ 最终医疗建议<br/>循证治疗方案]
    
    %% 样式定义
    classDef userClass fill:#ffffff,stroke:#000000,stroke-width:3px,color:#000000
    classDef coreClass fill:#ffffff,stroke:#000000,stroke-width:3px,color:#000000
    classDef toolClass fill:#ffffff,stroke:#000000,stroke-width:3px,color:#000000
    classDef reasoningClass fill:#ffffff,stroke:#000000,stroke-width:3px,color:#000000
    classDef outputClass fill:#ffffff,stroke:#000000,stroke-width:3px,color:#000000
    
    class User userClass
    class TxAgent,LLM,ToolRAG,ReasoningEngine coreClass
    class ToolUniverse,FDATools,OpenTargets,MonarchTools,SpecialTools,EmbeddingModel,ToolEmbedding toolClass
    class ConversationManager,FunctionCaller,ReasoningChecker reasoningClass
    class ToolResults,ResponseGenerator,FinalAnswer outputClass
```

## 图表2：API调用流程图

```mermaid
sequenceDiagram
    participant User as 👤 用户
    participant TxAgent as 🤖 TxAgent
    participant ToolRAG as 🔍 ToolRAG
    participant ToolUniverse as 🛠️ ToolUniverse
    participant LLM as 🧠 vLLM引擎
    participant Tools as 🔧 外部工具API
    
    User->>TxAgent: 输入医疗问题
    
    Note over TxAgent: 初始化阶段
    TxAgent->>TxAgent: initialize_tools_prompt()
    TxAgent->>ToolRAG: tool_RAG(message, rag_num)
    ToolRAG->>ToolRAG: rag_infer(query, top_k)
    ToolRAG-->>TxAgent: 返回相关工具列表
    
    TxAgent->>TxAgent: initialize_conversation()
    
    Note over TxAgent: 多轮推理循环
    loop 最多20轮推理
        TxAgent->>LLM: llm_infer(conversation, tools)
        LLM-->>TxAgent: 生成推理结果和工具调用
        
        alt 包含工具调用
            TxAgent->>TxAgent: run_function_call()
            TxAgent->>ToolUniverse: extract_function_call_json()
            ToolUniverse-->>TxAgent: 解析函数调用
            
            loop 每个工具调用
                alt 特殊工具调用
                    TxAgent->>TxAgent: 处理Finish/Tool_RAG/CallAgent
                else 普通工具调用
                    TxAgent->>ToolUniverse: run_one_function()
                    ToolUniverse->>Tools: 调用外部API
                    Tools-->>ToolUniverse: 返回工具结果
                    ToolUniverse-->>TxAgent: 格式化结果
                end
            end
            
            TxAgent->>TxAgent: 更新对话历史
        else 无工具调用
            Note over TxAgent: 直接返回推理结果
        end
        
        alt 遇到Finish工具或达到最大轮数
            break 结束推理循环
        end
    end
    
    TxAgent-->>User: 返回最终医疗建议
    
    Note over User,Tools: 🎯 核心特点：多步推理 + 工具增强 + 循证医学
```

## 图表3：数据流向图

```mermaid
flowchart TD
    %% 输入数据
    UserQuery[👤 用户医疗问题<br/>如：药物剂量调整]
    
    %% 数据预处理
    UserQuery --> QueryProcessing[📝 问题预处理<br/>提取关键信息]
    QueryProcessing --> ConversationInit[💬 对话初始化<br/>系统提示词设置]
    
    %% 工具检索阶段
    QueryProcessing --> ToolRetrieval[🔍 工具检索阶段]
    ToolRetrieval --> QueryEmbedding[📊 问题向量化<br/>GTE-Qwen2-1.5B]
    QueryEmbedding --> ToolMatching[🎯 工具匹配<br/>余弦相似度计算]
    
    %% 工具数据库
    ToolDB[(🗄️ 工具数据库<br/>211个工具描述)]
    ToolDB --> ToolEmbeddings[💾 工具嵌入向量<br/>预计算存储]
    ToolEmbeddings --> ToolMatching
    
    %% 推理循环数据流
    ToolMatching --> ReasoningLoop[🔄 推理循环数据流]
    ConversationInit --> ReasoningLoop
    
    subgraph ReasoningLoop [🔄 多步推理循环]
        ConversationHistory[📚 对话历史<br/>累积上下文]
        ToolPrompts[🛠️ 工具提示<br/>可用功能描述]
        
        ConversationHistory --> LLMInput[🧠 LLM输入<br/>上下文+工具+问题]
        ToolPrompts --> LLMInput
        
        LLMInput --> LLMOutput[⚡ LLM输出<br/>推理+工具调用]
        
        LLMOutput --> FunctionParsing[🔧 函数解析<br/>提取工具调用]
        FunctionParsing --> ToolExecution[⚙️ 工具执行]
        
        %% 工具执行分支
        ToolExecution --> FDACall[🏥 FDA API调用<br/>药物信息查询]
        ToolExecution --> OpenTargetsCall[🎯 OpenTargets调用<br/>靶点疾病关联]
        ToolExecution --> MonarchCall[👑 Monarch调用<br/>表型数据查询]
        
        FDACall --> ToolResults[📋 工具结果汇总]
        OpenTargetsCall --> ToolResults
        MonarchCall --> ToolResults
        
        ToolResults --> ResultFormatting[📝 结果格式化<br/>结构化输出]
        ResultFormatting --> ConversationHistory
    end
    
    %% 输出处理
    ReasoningLoop --> TerminationCheck{🏁 终止条件检查}
    TerminationCheck -->|继续推理| ReasoningLoop
    TerminationCheck -->|完成推理| FinalProcessing[✨ 最终处理]
    
    FinalProcessing --> EvidenceSynthesis[🔬 证据综合<br/>多源信息整合]
    EvidenceSynthesis --> ClinicalValidation[✅ 临床验证<br/>安全性检查]
    ClinicalValidation --> FinalAnswer[📋 最终医疗建议<br/>个性化治疗方案]
    
    %% 样式定义
    classDef inputClass fill:#ffffff,stroke:#000000,stroke-width:3px,color:#000000
    classDef processClass fill:#ffffff,stroke:#000000,stroke-width:3px,color:#000000
    classDef toolClass fill:#ffffff,stroke:#000000,stroke-width:3px,color:#000000
    classDef outputClass fill:#ffffff,stroke:#000000,stroke-width:3px,color:#000000
    classDef dataClass fill:#ffffff,stroke:#000000,stroke-width:3px,color:#000000
    
    class UserQuery,QueryProcessing,ConversationInit inputClass
    class ToolRetrieval,QueryEmbedding,ToolMatching,FunctionParsing,ResultFormatting processClass
    class ToolDB,ToolEmbeddings,ToolPrompts,ConversationHistory dataClass
    class ToolExecution,FDACall,OpenTargetsCall,MonarchCall,ToolResults toolClass
    class FinalProcessing,EvidenceSynthesis,ClinicalValidation,FinalAnswer outputClass
```

## 验证结果

✅ **图表显示状态**：
- 系统架构图：正常显示，白色背景，黑色文字
- API调用流程图：正常显示，时序图格式清晰
- 数据流向图：正常显示，流程图结构完整

✅ **配色验证**：
- 背景色：白色 (#ffffff)
- 文字色：黑色 (#000000)
- 边框色：黑色，3px粗细
- 适合微信公众号等平台显示

✅ **内容完整性**：
- 所有关键组件都已标注
- 中文注释清晰易懂
- 流程逻辑完整准确
