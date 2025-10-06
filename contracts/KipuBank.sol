// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KipuBank
 * @author [Tu Nombre Aquí]
 * @notice Un contrato bancario simple que permite a los usuarios depositar y retirar tokens nativos (ETH)
 * con un límite global de depósitos y un límite por transacción de retiro.
 */
contract KipuBank {
    /* *******************************************************************
     * 1. CUSTOM ERRORS
     * *******************************************************************/

    /// @dev Se dispara cuando el monto del depósito supera el límite restante del banco.
    error Bank__CapExceeded(uint256 currentBalance, uint256 bankCap, uint256 depositAmount);
    
    /// @dev Se dispara cuando un retiro excede el umbral fijo por transacción.
    error Bank__WithdrawalLimitExceeded(uint256 limit, uint256 requestedAmount);
    
    /// @dev Se dispara cuando un retiro solicitado excede el saldo del usuario.
    error Bank__InsufficientBalance(uint256 availableBalance, uint256 requestedAmount);
    
    /// @dev Se dispara si la transferencia nativa de ETH falla.
    error Bank__TransferFailed();
    
    /// @dev Se dispara si un usuario intenta depositar 0 ETH.
    error Bank__ZeroDeposit();
    
    /// @dev Se dispara si se intenta retirar 0 ETH.
    error Bank__ZeroWithdrawal();


    /* *******************************************************************
     * 2. STATE VARIABLES
     * *******************************************************************/

    // --- Immutable / Constant Variables ---

    /// @dev El umbral máximo de retiro por transacción que cualquier usuario puede realizar.
    /// @custom:security Implementa un límite de retiro por transacción para mitigar grandes pérdidas en caso de exploit.
    immutable public i_withdrawalLimitPerTx;

    /// @dev El límite total (cap) de tokens nativos que el contrato puede contener.
    /// @custom:security Limita la exposición total del contrato a un valor fijo.
    immutable public i_bankCap;

    // --- Storage Variables (Clean, readable, well-commented) ---

    /// @dev Mapeo que almacena el saldo de ETH de cada usuario.
    /// La clave es la dirección del usuario, el valor es su saldo.
    mapping(address => uint256) private s_balances;

    /// @dev Contador del número total de depósitos exitosos.
    uint256 private s_depositCount;

    /// @dev Contador del número total de retiros exitosos.
    uint256 private s_withdrawalCount;


    /* *******************************************************************
     * 3. EVENTS
     * *******************************************************************/

    /// @dev Se emite cuando un usuario deposita ETH exitosamente.
    /// @param user La dirección del usuario que depositó.
    /// @param amount La cantidad de ETH depositada (en wei).
    /// @param newBalance El nuevo saldo del usuario.
    event Deposit(address indexed user, uint256 amount, uint256 newBalance);

    /// @dev Se emite cuando un usuario retira ETH exitosamente.
    /// @param user La dirección del usuario que retiró.
    /// @param amount La cantidad de ETH retirada (en wei).
    /// @param newBalance El nuevo saldo del usuario.
    event Withdrawal(address indexed user, uint256 amount, uint256 newBalance);


    /* *******************************************************************
     * 4. CONSTRUCTOR
     * *******************************************************************/

    /**
     * @notice Inicializa el contrato KipuBank.
     * @param bankCap_ El límite global máximo de depósitos (en wei).
     * @param withdrawalLimitPerTx_ El límite de retiro por transacción (en wei).
     */
    constructor(uint256 bankCap_, uint256 withdrawalLimitPerTx_) {
        i_bankCap = bankCap_;
        i_withdrawalLimitPerTx = withdrawalLimitPerTx_;
    }


    /* *******************************************************************
     * 5. MODIFIERS
     * *******************************************************************/

    /// @dev Modificador que comprueba que el monto total de ETH en el contrato
    /// más el depósito actual no exceda el límite global (i_bankCap).
    modifier onlyBelowBankCap() {
        if (address(this).balance + msg.value > i_bankCap) {
            revert Bank__CapExceeded(address(this).balance, i_bankCap, msg.value);
        }
        _;
    }


    /* *******************************************************************
     * 6. EXTERNAL/PUBLIC FUNCTIONS
     * *******************************************************************/

    /**
     * @notice Permite a los usuarios depositar tokens nativos (ETH) en su bóveda personal.
     * @dev Es una función `external payable` y sigue el patrón checks-effects-interactions.
     * @custom:security Utiliza el modificador `onlyBelowBankCap` para validar el tope global.
     * @custom:security Usa `msg.sender` como clave para el almacenamiento personal.
     */
    function deposit() external payable onlyBelowBankCap {
        // 1. Checks
        if (msg.value == 0) {
            revert Bank__ZeroDeposit();
        }

        // 2. Effects
        s_balances[msg.sender] += msg.value;
        s_depositCount++;

        // 3. Interactions (Events)
        emit Deposit(msg.sender, msg.value, s_balances[msg.sender]);
    }

    /**
     * @notice Permite a un usuario retirar ETH de su bóveda personal.
     * @param amount La cantidad de ETH (en wei) a retirar.
     * @dev Sigue el patrón checks-effects-interactions y maneja la transferencia de ETH de forma segura.
     * @custom:security Valida que el monto no exceda el límite por transacción y el saldo del usuario.
     * @custom:security La transferencia de ETH es la ÚLTIMA acción.
     */
    function withdraw(uint256 amount) external {
        // 1. Checks
        if (amount == 0) {
            revert Bank__ZeroWithdrawal();
        }
        if (amount > i_withdrawalLimitPerTx) {
            revert Bank__WithdrawalLimitExceeded(i_withdrawalLimitPerTx, amount);
        }
        if (amount > s_balances[msg.sender]) {
            revert Bank__InsufficientBalance(s_balances[msg.sender], amount);
        }

        // 2. Effects
        s_balances[msg.sender] -= amount;
        s_withdrawalCount++;

        // 3. Interactions (Transferencia y Evento)
        
        // Manejo seguro de transferencia nativa (.call en lugar de .transfer/.send)
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            // Revertir los cambios de estado si la transferencia falla
            revert Bank__TransferFailed();
        }
        
        emit Withdrawal(msg.sender, amount, s_balances[msg.sender]);
    }

    /* *******************************************************************
     * 7. VIEW FUNCTIONS
     * *******************************************************************/

    /**
     * @notice Obtiene el saldo actual de ETH de la bóveda personal de un usuario.
     * @param user La dirección del usuario.
     * @return El saldo del usuario en wei.
     */
    function getBalance(address user) external view returns (uint256) {
        return s_balances[user];
    }
    
    /**
     * @notice Obtiene el contador total de depósitos.
     * @return El número total de depósitos.
     */
    function getDepositCount() external view returns (uint256) {
        return _getDepositCount(); // Llama a la función privada
    }

    /**
     * @notice Obtiene el contador total de retiros.
     * @return El número total de retiros.
     */
    function getWithdrawalCount() external view returns (uint256) {
        return s_withdrawalCount;
    }

    /* *******************************************************************
     * 8. PRIVATE FUNCTIONS
     * *******************************************************************/

    /**
     * @notice Devuelve el contador interno del número total de depósitos.
     * @dev Función interna simple, utilizada por `getDepositCount()` para cumplir con el requisito de función `private`.
     * @return El número total de depósitos.
     */
    function _getDepositCount() private view returns (uint256) {
        return s_depositCount;
    }
}