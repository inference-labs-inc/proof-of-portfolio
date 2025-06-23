import os
import json
import math
import numpy as np
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional, Any

from numpy import sort


class Main:
    def __init__(self):
        # Use a path relative to the script's location
        script_dir = Path(os.path.dirname(os.path.abspath(__file__)))
        self.children_dir = script_dir.parent / "data" / "children"
        self.risk_free_rate = 0.05  # Annual risk-free rate (5%)

    def get_miner_score(self, miner_hotkey: str) -> float:
        """
        Calculate the score for a specific miner based on their trading performance.

        Args:
            miner_hotkey (str): The hotkey identifier for the miner

        Returns:
            float: The calculated score for the miner
        """
        # Check if miner data exists
        miner_file = self.children_dir / f"{miner_hotkey}.json"
        if not miner_file.exists():
            print(f"No data found for miner: {miner_hotkey}")
            return 0.0

        # Load miner data
        try:
            with open(miner_file, 'r') as f:
                positions = json.load(f)
        except Exception as e:
            print(f"Error loading data for miner {miner_hotkey}: {e}")
            return 0.0

        # Calculate daily returns
        daily_returns = self._calculate_daily_returns(positions)

        if not daily_returns:
            print(f"No valid daily returns found for miner: {miner_hotkey}")
            return 0.0

        # Calculate metrics
        calmar_ratio = self._calculate_calmar_ratio(daily_returns)
        sharpe_ratio = self._calculate_sharpe_ratio(daily_returns)
        omega_ratio = self._calculate_omega_ratio(daily_returns)
        sortino_ratio = self._calculate_sortino_ratio(daily_returns)
        statistical_confidence = self._calculate_statistical_confidence(daily_returns)

        # Apply penalties
        max_drawdown = self._calculate_max_drawdown(daily_returns)
        risk_profile_penalty = self._calculate_risk_profile_penalty(positions)

        # If max drawdown exceeds 10%, return 0 score
        if max_drawdown > 0.10:
            print(f"Miner {miner_hotkey} exceeded 10% max drawdown: {max_drawdown:.2%}")
            return 0.0

        # Calculate final score with weights
        score = (
            0.20 * calmar_ratio +
            0.20 * sharpe_ratio +
            0.20 * omega_ratio +
            0.20 * sortino_ratio +
            0.20 * statistical_confidence
        )

        # Apply risk profile penalty
        score *= (1 - risk_profile_penalty)

        return max(0.0, score)

    def get_all_scores(self) -> Dict[str, float]:
        """
        Calculate scores for all miners in the data/children directory.

        Returns:
            Dict[str, float]: Dictionary mapping miner hotkeys to their scores
        """
        scores = {}

        # Check if children directory exists
        if not self.children_dir.exists():
            print(f"Children directory not found: {self.children_dir}")
            return scores

        # Process each miner file
        for miner_file in self.children_dir.glob("*.json"):
            miner_hotkey = miner_file.stem
            score = self.get_miner_score(miner_hotkey)
            scores[miner_hotkey] = score

        return scores

    def _calculate_daily_returns(self, positions: List[Dict]) -> List[float]:
        """
        Calculate daily returns from position data.

        Args:
            positions (List[Dict]): List of position objects

        Returns:
            List[float]: List of daily returns
        """
        # Group positions by day
        daily_positions = {}

        for position in positions:
            if position.get("is_closed_position", False):
                # Use close_ms for closed positions
                close_time = position.get("close_ms", 0)
                if close_time > 0:
                    # Convert milliseconds to date string (YYYY-MM-DD)
                    close_date = datetime.fromtimestamp(close_time / 1000).strftime('%Y-%m-%d')

                    if close_date not in daily_positions:
                        daily_positions[close_date] = []

                    daily_positions[close_date].append(position)

        # Calculate daily returns
        daily_returns = []

        for date, day_positions in sorted(daily_positions.items()):
            # Calculate return for the day based on closed positions
            day_return = 1.0
            for position in day_positions:
                position_return = position.get("return_at_close", 1.0)
                day_return *= position_return

            # Convert to percentage return
            daily_returns.append(day_return - 1.0)

        return daily_returns

    def _calculate_calmar_ratio(self, daily_returns: List[float]) -> float:
        """
        Calculate the Calmar Ratio: Annualized Return / Max Drawdown

        Args:
            daily_returns (List[float]): List of daily returns

        Returns:
            float: Calmar Ratio
        """
        if not daily_returns:
            return 0.0

        # Calculate annualized return
        n = len(daily_returns)
        if n == 0:
            return 0.0

        annualized_return = (365 / n) * sum(daily_returns) - self.risk_free_rate

        # Calculate max drawdown
        max_drawdown = self._calculate_max_drawdown(daily_returns)

        # Avoid division by zero
        if max_drawdown <= 0.01:
            max_drawdown = 0.01

        return annualized_return / max_drawdown

    def _calculate_sharpe_ratio(self, daily_returns: List[float]) -> float:
        """
        Calculate the Sharpe Ratio: (Annualized Return - Risk Free Rate) / Annualized Volatility

        Args:
            daily_returns (List[float]): List of daily returns

        Returns:
            float: Sharpe Ratio
        """
        if not daily_returns:
            return 0.0

        n = len(daily_returns)
        if n < 2:
            return 0.0

        # Calculate annualized return
        annualized_return = (365 / n) * sum(daily_returns) - self.risk_free_rate

        # Calculate annualized volatility
        volatility = np.std(daily_returns, ddof=1)
        annualized_volatility = volatility * math.sqrt(365 / n)

        # Use minimum volatility of 1%
        if annualized_volatility < 0.01:
            annualized_volatility = 0.01

        return annualized_return / annualized_volatility

    def _calculate_omega_ratio(self, daily_returns: List[float]) -> float:
        """
        Calculate the Omega Ratio: Sum of positive returns / Absolute sum of negative returns

        Args:
            daily_returns (List[float]): List of daily returns

        Returns:
            float: Omega Ratio
        """
        if not daily_returns:
            return 0.0

        positive_returns = sum(max(r, 0) for r in daily_returns)
        negative_returns = abs(sum(min(r, 0) for r in daily_returns))

        # Use minimum denominator of 1%
        if negative_returns < 0.01:
            negative_returns = 0.01

        return positive_returns / negative_returns

    def _calculate_sortino_ratio(self, daily_returns: List[float]) -> float:
        """
        Calculate the Sortino Ratio: (Annualized Return - Risk Free Rate) / Annualized Downside Deviation

        Args:
            daily_returns (List[float]): List of daily returns

        Returns:
            float: Sortino Ratio
        """
        if not daily_returns:
            return 0.0

        n = len(daily_returns)
        if n < 2:
            return 0.0

        # Calculate annualized return
        annualized_return = (365 / n) * sum(daily_returns) - self.risk_free_rate

        # Calculate downside deviation (only negative returns)
        negative_returns = [r for r in daily_returns if r < 0]

        if not negative_returns:
            return annualized_return / 0.01  # Use minimum downside deviation of 1%

        downside_deviation = np.std(negative_returns, ddof=1)
        annualized_downside_deviation = downside_deviation * math.sqrt(365 / n)

        # Use minimum downside deviation of 1%
        if annualized_downside_deviation < 0.01:
            annualized_downside_deviation = 0.01

        return annualized_return / annualized_downside_deviation

    def _calculate_statistical_confidence(self, daily_returns: List[float]) -> float:
        """
        Calculate Statistical Confidence using t-statistic

        Args:
            daily_returns (List[float]): List of daily returns

        Returns:
            float: Statistical Confidence score
        """
        if not daily_returns:
            return 0.0

        n = len(daily_returns)
        if n < 2:
            return 0.0

        mean_return = np.mean(daily_returns)
        std_dev = np.std(daily_returns, ddof=1)

        if std_dev == 0:
            return 0.0

        # Calculate t-statistic
        t_stat = abs(mean_return / (std_dev / math.sqrt(n)))

        # Normalize t-statistic to a score between 0 and 1
        # Higher t-statistic means higher confidence
        confidence_score = min(1.0, t_stat / 10.0)

        return confidence_score

    def _calculate_max_drawdown(self, daily_returns: List[float]) -> float:
        """
        Calculate the maximum drawdown from daily returns

        Args:
            daily_returns (List[float]): List of daily returns

        Returns:
            float: Maximum drawdown as a decimal (0.10 = 10%)
        """
        if not daily_returns:
            return 0.0

        # Convert returns to cumulative returns
        cumulative = [1.0]
        for r in daily_returns:
            cumulative.append(cumulative[-1] * (1 + r))

        # Calculate running maximum
        running_max = np.maximum.accumulate(cumulative)

        # Calculate drawdowns
        drawdowns = (running_max - cumulative) / running_max

        return float(np.max(drawdowns))

    def _calculate_risk_profile_penalty(self, positions: List[Dict]) -> float:
        """
        Calculate risk profile penalty based on trading behavior

        Args:
            positions (List[Dict]): List of position objects

        Returns:
            float: Risk profile penalty as a decimal (0.0 to 1.0)
        """
        penalty = 0.0

        # Check for risky behaviors in positions
        for position in positions:
            orders = position.get("orders", [])

            # Check for stepping into positions multiple times
            if len(orders) >= 3:
                # Count how many times leverage was increased on a losing position
                leverage_increases = 0
                max_leverage = 0
                entry_leverage = 0

                for i, order in enumerate(orders):
                    if i == 0:
                        # First order establishes the position
                        entry_leverage = abs(order.get("leverage", 0))
                        max_leverage = entry_leverage
                    else:
                        current_leverage = abs(order.get("leverage", 0))

                        # Check if leverage increased
                        if current_leverage > max_leverage:
                            max_leverage = current_leverage

                            # Check if position is losing
                            current_return = position.get("current_return", 1.0)
                            if current_return < 1.0:
                                leverage_increases += 1

                # Penalty for increasing leverage twice on a losing position
                if leverage_increases >= 2:
                    penalty += 0.1

                # Penalty for using more than 50% of available leverage or increasing by 150%
                trade_pair = position.get("trade_pair", [])
                if len(trade_pair) >= 5:
                    # Check if it's forex or crypto
                    pair_name = trade_pair[0] if len(trade_pair) > 0 else ""

                    # Determine max allowed leverage based on asset type
                    max_allowed = 5.0  # Default for forex
                    if len(pair_name) >= 3 and pair_name[-3:] != "JPY" and pair_name[:3] != "USD":
                        max_allowed = 0.5  # For crypto

                    # Check if leverage exceeds 50% of max allowed
                    if max_leverage > (0.5 * max_allowed):
                        penalty += 0.05

                    # Check if leverage increased by 150% relative to entry
                    if entry_leverage > 0 and max_leverage > (1.5 * entry_leverage):
                        penalty += 0.05

        # Cap penalty at 1.0
        return min(1.0, penalty)


if __name__ == "__main__":
    main = Main()
    print(main.get_all_scores())
